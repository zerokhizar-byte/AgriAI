import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;


import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

class DiseaseDetectionService {
  DiseaseDetectionService._();

  static final DiseaseDetectionService instance =
      DiseaseDetectionService._();

  static const String _modelAsset =
      'assets/models/disease_model.onnx';

  static const String _classNamesAsset =
      'assets/models/class_names.json';

  static const int _imageSize = 224;
  static const int _numberOfClasses = 19;

  static const List<double> _mean = <double>[
    0.485,
    0.456,
    0.406,
  ];

  static const List<double> _std = <double>[
    0.229,
    0.224,
    0.225,
  ];

  OnnxRuntime? _runtime;
  OrtSession? _session;
  List<String>? _classNames;

  Future<void> _initialize() async {
    if (_session != null && _classNames != null) {
      return;
    }

    _runtime ??= OnnxRuntime();

    _session ??= await _runtime!.createSessionFromAsset(
      _modelAsset,
    );

    final String classJson = await rootBundle.loadString(
      _classNamesAsset,
    );

    final dynamic decoded = jsonDecode(classJson);

    if (decoded is! List) {
      throw const DiseaseDetectionException(
        'Invalid disease class mapping.',
      );
    }

    final List<String> classes = decoded
        .map((dynamic value) => value.toString())
        .toList();

    if (classes.length != _numberOfClasses) {
      throw DiseaseDetectionException(
        'Expected $_numberOfClasses disease classes, '
        'but found ${classes.length}.',
      );
    }

    _classNames = classes;
  }

  Future<DiseaseDetectionResult> detectDisease(
    File imageFile,
  ) async {
    if (!await imageFile.exists()) {
      throw const DiseaseDetectionException(
        'The selected image could not be found.',
      );
    }

    try {
      await _initialize();

      final Uint8List bytes =
          await imageFile.readAsBytes();

      final img.Image? decoded =
          img.decodeImage(bytes);

      if (decoded == null) {
        throw const DiseaseDetectionException(
          'Unable to read the selected image.',
        );
      }

      final img.Image resized = img.copyResize(
        decoded,
        width: _imageSize,
        height: _imageSize,
        interpolation: img.Interpolation.linear,
      );

      final List<double> inputData =
          _preprocessImage(resized);

      final OrtValue inputTensor =
          await OrtValue.fromList(
        inputData,
        <int>[
          1,
          3,
          _imageSize,
          _imageSize,
        ],
      );

      final OrtSession session = _session!;

      final String inputName =
          session.inputNames.first;

      final String outputName =
          session.outputNames.first;

      final Map<String, OrtValue> inputs =
          <String, OrtValue>{
        inputName: inputTensor,
      };

      final Map<String, OrtValue> outputs =
          await session.run(inputs);

      final OrtValue? outputTensor =
          outputs[outputName];

      if (outputTensor == null) {
        await inputTensor.dispose();

        for (final OrtValue tensor
            in outputs.values) {
          await tensor.dispose();
        }

        throw const DiseaseDetectionException(
          'The disease model returned no output.',
        );
      }

      final List<dynamic> rawOutput =
          await outputTensor.asFlattenedList();

      final List<double> logits = rawOutput
          .map(
            (dynamic value) =>
                (value as num).toDouble(),
          )
          .toList();

      if (logits.length != _numberOfClasses) {
        await inputTensor.dispose();

        for (final OrtValue tensor
            in outputs.values) {
          await tensor.dispose();
        }

        throw DiseaseDetectionException(
          'Unexpected model output size: '
          '${logits.length}.',
        );
      }

      final List<double> probabilities =
          _softmax(logits);

      int bestIndex = 0;

      for (int i = 1;
          i < probabilities.length;
          i++) {
        if (probabilities[i] >
            probabilities[bestIndex]) {
          bestIndex = i;
        }
      }

      final double confidence =
          probabilities[bestIndex];

      final String rawClassName =
          _classNames![bestIndex];

      final DiseaseInfo diseaseInfo =
          _getDiseaseInfo(rawClassName);

      await inputTensor.dispose();

      for (final OrtValue tensor
          in outputs.values) {
        await tensor.dispose();
      }

      return DiseaseDetectionResult(
        diseaseName: diseaseInfo.diseaseName,
        cropName: diseaseInfo.cropName,
        className: rawClassName,
        confidence: confidence,
        isHealthy: diseaseInfo.isHealthy,
        description: diseaseInfo.description,
        treatment: diseaseInfo.treatment,
        prevention: diseaseInfo.prevention,
      );
    } on DiseaseDetectionException {
      rethrow;
    } catch (error) {
      throw DiseaseDetectionException(
        'Disease analysis failed: $error',
      );
    }
  }

  Future<DiseaseDetectionResult> detectDiseaseFromPath(
    String imagePath,
  ) async {
    return detectDisease(
      File(imagePath),
    );
  }

  List<double> _preprocessImage(
    img.Image image,
  ) {
    final Uint8List rgbBytes =
        image.getBytes(
      order: img.ChannelOrder.rgb,
    );

    final int pixelCount =
        _imageSize * _imageSize;

    final List<double> red =
        List<double>.filled(pixelCount, 0);

    final List<double> green =
        List<double>.filled(pixelCount, 0);

    final List<double> blue =
        List<double>.filled(pixelCount, 0);

    for (int i = 0; i < pixelCount; i++) {
      final int offset = i * 3;

      red[i] =
          (rgbBytes[offset] / 255.0 - _mean[0]) /
              _std[0];

      green[i] =
          (rgbBytes[offset + 1] / 255.0 -
                  _mean[1]) /
              _std[1];

      blue[i] =
          (rgbBytes[offset + 2] / 255.0 -
                  _mean[2]) /
              _std[2];
    }

    return <double>[
      ...red,
      ...green,
      ...blue,
    ];
  }

  List<double> _softmax(
    List<double> logits,
  ) {
    double maxLogit = logits.first;

    for (final double value in logits.skip(1)) {
      if (value > maxLogit) {
        maxLogit = value;
      }
    }

    final List<double> exponentials =
        logits
            .map(
              (double value) =>
                  math.exp(value - maxLogit),
            )
            .toList();

    final double sum =
        exponentials.fold(
      0.0,
      (double total, double value) =>
          total + value,
    );

    if (sum == 0) {
      return List<double>.filled(
        logits.length,
        0.0,
      );
    }

    return exponentials
        .map(
          (double value) => value / sum,
        )
        .toList();
  }

  DiseaseInfo _getDiseaseInfo(
    String className,
  ) {
    switch (className) {
      case 'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot':
        return const DiseaseInfo(
          cropName: 'Corn',
          diseaseName:
              'Cercospora Leaf Spot / Gray Leaf Spot',
          isHealthy: false,
          description:
              'A fungal leaf disease that produces gray, tan, or brown lesions on corn leaves.',
          treatment:
              'Remove heavily affected plant material where practical and follow locally recommended fungicide practices for corn.',
          prevention:
              'Maintain field sanitation, use resistant varieties where available, and avoid practices that promote prolonged leaf wetness.',
        );

      case 'Corn_(maize)___Common_rust_':
        return const DiseaseInfo(
          cropName: 'Corn',
          diseaseName: 'Common Rust',
          isHealthy: false,
          description:
              'A fungal disease that produces characteristic rust-colored pustules on corn leaves.',
          treatment:
              'Monitor disease development and use locally recommended fungicide management when economically justified.',
          prevention:
              'Use resistant varieties where available and maintain balanced crop management.',
        );

      case 'Corn_(maize)___Northern_Leaf_Blight':
        return const DiseaseInfo(
          cropName: 'Corn',
          diseaseName: 'Northern Leaf Blight',
          isHealthy: false,
          description:
              'A fungal disease that causes elongated gray-green to brown lesions on corn leaves.',
          treatment:
              'Use locally recommended disease-management practices and fungicides when appropriate.',
          prevention:
              'Use resistant hybrids, manage crop residues, and maintain good field sanitation.',
        );

      case 'Corn_(maize)___healthy':
        return const DiseaseInfo(
          cropName: 'Corn',
          diseaseName: 'Healthy Corn Leaf',
          isHealthy: true,
          description:
              'The model identified the submitted corn leaf as healthy.',
          treatment:
              'No disease treatment is indicated by this prediction.',
          prevention:
              'Continue regular monitoring, balanced nutrition, appropriate irrigation, and good field hygiene.',
        );

      case 'Pepper,_bell___Bacterial_spot':
        return const DiseaseInfo(
          cropName: 'Pepper',
          diseaseName: 'Bacterial Spot',
          isHealthy: false,
          description:
              'A bacterial disease that can cause dark spots and lesions on pepper leaves and fruit.',
          treatment:
              'Remove severely affected material and follow locally recommended bacterial-disease management practices.',
          prevention:
              'Use clean planting material, avoid unnecessary leaf wetness, and maintain good field sanitation.',
        );

      case 'Pepper,_bell___healthy':
        return const DiseaseInfo(
          cropName: 'Pepper',
          diseaseName: 'Healthy Pepper Leaf',
          isHealthy: true,
          description:
              'The model identified the submitted pepper leaf as healthy.',
          treatment:
              'No disease treatment is indicated by this prediction.',
          prevention:
              'Continue regular crop monitoring, balanced nutrition, irrigation, and sanitation.',
        );

      case 'Potato___Early_blight':
        return const DiseaseInfo(
          cropName: 'Potato',
          diseaseName: 'Early Blight',
          isHealthy: false,
          description:
              'A fungal disease commonly associated with dark lesions and concentric rings on potato leaves.',
          treatment:
              'Remove severely affected foliage where practical and follow locally recommended fungicide programs.',
          prevention:
              'Maintain crop sanitation, balanced nutrition, and avoid prolonged leaf wetness.',
        );

      case 'Potato___Late_blight':
        return const DiseaseInfo(
          cropName: 'Potato',
          diseaseName: 'Late Blight',
          isHealthy: false,
          description:
              'A serious potato disease that can rapidly damage foliage under favorable conditions.',
          treatment:
              'Seek prompt local agricultural guidance and follow recommended late-blight management and fungicide programs.',
          prevention:
              'Use healthy planting material, monitor weather and disease conditions, and maintain field sanitation.',
        );

      case 'Potato___healthy':
        return const DiseaseInfo(
          cropName: 'Potato',
          diseaseName: 'Healthy Potato Leaf',
          isHealthy: true,
          description:
              'The model identified the submitted potato leaf as healthy.',
          treatment:
              'No disease treatment is indicated by this prediction.',
          prevention:
              'Continue routine monitoring, balanced nutrition, appropriate irrigation, and field sanitation.',
        );

      case 'Tomato___Bacterial_spot':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName: 'Bacterial Spot',
          isHealthy: false,
          description:
              'A bacterial disease that produces dark spots and lesions on tomato foliage and fruit.',
          treatment:
              'Remove severely affected material where practical and follow locally recommended bacterial-disease management.',
          prevention:
              'Use clean seed or planting material, reduce leaf wetness, and maintain field sanitation.',
        );

      case 'Tomato___Early_blight':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName: 'Early Blight',
          isHealthy: false,
          description:
              'A fungal disease that commonly causes dark lesions with concentric rings on tomato leaves.',
          treatment:
              'Remove severely affected leaves and follow locally recommended fungicide-management practices.',
          prevention:
              'Maintain sanitation, avoid prolonged leaf wetness, and provide appropriate plant spacing.',
        );

      case 'Tomato___Late_blight':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName: 'Late Blight',
          isHealthy: false,
          description:
              'A potentially destructive disease that can cause rapidly expanding lesions on tomato foliage.',
          treatment:
              'Seek prompt local agricultural guidance and follow recommended late-blight management practices.',
          prevention:
              'Monitor crops frequently, reduce prolonged leaf wetness, and use healthy planting material.',
        );

      case 'Tomato___Leaf_Mold':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName: 'Leaf Mold',
          isHealthy: false,
          description:
              'A fungal disease that commonly develops under warm, humid conditions.',
          treatment:
              'Remove severely affected foliage where practical and improve environmental conditions while following local recommendations.',
          prevention:
              'Improve air circulation, avoid excessive humidity around foliage, and reduce prolonged leaf wetness.',
        );

      case 'Tomato___Septoria_leaf_spot':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName: 'Septoria Leaf Spot',
          isHealthy: false,
          description:
              'A fungal leaf disease that produces numerous small spots on tomato foliage.',
          treatment:
              'Remove severely affected lower leaves and follow locally recommended fungicide practices.',
          prevention:
              'Maintain sanitation, avoid overhead irrigation when possible, and improve airflow between plants.',
        );

      case 'Tomato___Spider_mites Two-spotted_spider_mite':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName:
              'Spider Mites (Two-spotted Spider Mite)',
          isHealthy: false,
          description:
              'A pest infestation that can cause stippling, discoloration, and weakening of tomato leaves.',
          treatment:
              'Inspect leaf undersides and follow locally recommended integrated pest-management practices.',
          prevention:
              'Monitor plants regularly, manage dust and plant stress, and encourage beneficial predators where appropriate.',
        );

      case 'Tomato___Target_Spot':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName: 'Target Spot',
          isHealthy: false,
          description:
              'A fungal disease associated with circular lesions that may develop target-like patterns.',
          treatment:
              'Remove severely affected foliage where practical and follow locally recommended disease-management practices.',
          prevention:
              'Maintain good airflow, field sanitation, and avoid prolonged leaf wetness.',
        );

      case 'Tomato___Tomato_Yellow_Leaf_Curl_Virus':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName:
              'Tomato Yellow Leaf Curl Virus',
          isHealthy: false,
          description:
              'A viral disease associated with yellowing, curling, and stunted tomato growth.',
          treatment:
              'Remove severely affected plants where appropriate and manage the insect vector according to local recommendations.',
          prevention:
              'Use healthy planting material and manage whiteflies through integrated pest management.',
        );

      case 'Tomato___Tomato_mosaic_virus':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName: 'Tomato Mosaic Virus',
          isHealthy: false,
          description:
              'A viral disease that can cause mosaic patterns, leaf distortion, and reduced plant vigor.',
          treatment:
              'Remove infected plants where appropriate and avoid spreading contaminated plant sap between plants.',
          prevention:
              'Use clean planting material, sanitize tools, and maintain good crop hygiene.',
        );

      case 'Tomato___healthy':
        return const DiseaseInfo(
          cropName: 'Tomato',
          diseaseName: 'Healthy Tomato Leaf',
          isHealthy: true,
          description:
              'The model identified the submitted tomato leaf as healthy.',
          treatment:
              'No disease treatment is indicated by this prediction.',
          prevention:
              'Continue regular monitoring, balanced nutrition, appropriate irrigation, and good field sanitation.',
        );

      default:
        return const DiseaseInfo(
          cropName: 'Unknown',
          diseaseName: 'Unknown',
          isHealthy: false,
          description:
              'The model returned a class that is not mapped in the application.',
          treatment:
              'Do not apply treatment based on this result alone.',
          prevention:
              'Capture a clear image and repeat the analysis.',
        );
    }
  }

  Future<void> dispose() async {
    final OrtSession? session = _session;

    _session = null;
    _runtime = null;
    _classNames = null;

    if (session != null) {
      await session.close();
    }
  }
}

class DiseaseInfo {
  final String cropName;
  final String diseaseName;
  final bool isHealthy;
  final String description;
  final String treatment;
  final String prevention;

  const DiseaseInfo({
    required this.cropName,
    required this.diseaseName,
    required this.isHealthy,
    required this.description,
    required this.treatment,
    required this.prevention,
  });
}

class DiseaseDetectionResult {
  final String diseaseName;
  final String cropName;
  final String className;
  final double confidence;
  final bool isHealthy;
  final String description;
  final String treatment;
  final String prevention;

  const DiseaseDetectionResult({
    required this.diseaseName,
    required this.cropName,
    required this.className,
    required this.confidence,
    required this.isHealthy,
    required this.description,
    required this.treatment,
    required this.prevention,
  });

  factory DiseaseDetectionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return DiseaseDetectionResult(
      diseaseName:
          json['diseaseName']?.toString() ??
              'Unknown',
      cropName:
          json['cropName']?.toString() ??
              'Unknown',
      className:
          json['className']?.toString() ??
              '',
      confidence:
          _toDouble(json['confidence']),
      isHealthy:
          json['isHealthy'] == true,
      description:
          json['description']?.toString() ?? '',
      treatment:
          json['treatment']?.toString() ?? '',
      prevention:
          json['prevention']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'diseaseName': diseaseName,
      'cropName': cropName,
      'className': className,
      'confidence': confidence,
      'isHealthy': isHealthy,
      'description': description,
      'treatment': treatment,
      'prevention': prevention,
    };
  }

  double get confidencePercentage {
    if (confidence <= 1) {
      return confidence * 100;
    }

    return confidence;
  }

  String get confidenceDisplay {
    return '${confidencePercentage.toStringAsFixed(1)}%';
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }
}

class DiseaseDetectionException
    implements Exception {
  final String message;

  const DiseaseDetectionException(
    this.message,
  );

  @override
  String toString() => message;
}
