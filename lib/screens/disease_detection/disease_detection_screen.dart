import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/disease_detection_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  final VoidCallback? onDetectionComplete;

  const DiseaseDetectionScreen({
    super.key,
    this.onDetectionComplete,
  });

  @override
  State<DiseaseDetectionScreen> createState() =>
      _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState
    extends State<DiseaseDetectionScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isAnalyzing = false;

  Future<void> _pickImage(
    ImageSource source,
  ) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to select the image. Please try again.',
      );
    }
  }

  Future<void> _analyzeImage() async {
    final File? image = _selectedImage;

    if (image == null) {
      _showMessage(
        'Please select a plant leaf image first.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final DiseaseDetectionResult result =
          await DiseaseDetectionService.instance
              .detectDisease(image);

      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
      });

      widget.onDetectionComplete?.call();

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DiseaseResultScreen(
            image: image,
            result: result,
          ),
        ),
      );
    } on DiseaseDetectionException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
      });

      _showMessage(error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
      });

      _showMessage(
        'Unable to analyze the image. Please try again.',
      );
    }
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        _selectedImage != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Disease Detection',
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _DiseaseIntroCard(),
              const SizedBox(height: 20),
              const Text(
                'Leaf Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _ImagePreviewCard(
                image: _selectedImage,
                onRemove:
                    hasImage
                        ? _removeImage
                        : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceButton(
                      icon:
                          Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        _pickImage(
                          ImageSource.camera,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: _ImageSourceButton(
                      icon:
                          Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        _pickImage(
                          ImageSource.gallery,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _DetectionTipsCard(),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isAnalyzing
                          ? null
                          : _analyzeImage,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary
                            .withValues(
                      alpha: 0.55,
                    ),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration:
                        const Duration(
                      milliseconds: 180,
                    ),
                    child:
                        _isAnalyzing
                            ? const SizedBox(
                                key: ValueKey(
                                  'analyzing',
                                ),
                                width: 23,
                                height: 23,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Row(
                                key: ValueKey(
                                  'analyze',
                                ),
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons
                                        .auto_awesome,
                                    size: 20,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Analyze Plant',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          14.5,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiseaseIntroCard
    extends StatelessWidget {
  const _DiseaseIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius:
            BorderRadius.circular(
          AppDimensions.radius22,
        ),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.local_florist_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Plant Disease Detection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Upload a clear leaf image and use AI to identify possible plant diseases.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w500,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewCard
    extends StatelessWidget {
  final File? image;
  final VoidCallback? onRemove;

  const _ImagePreviewCard({
    this.image,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (image == null) {
      return Container(
        width: double.infinity,
        height: 245,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: const Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            SizedBox(height: 12),
            Text(
              'No image selected',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w700,
                color:
                    AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Take a photo or choose one from your gallery',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 285,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            image!,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black54,
              shape:
                  const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder:
                    const CircleBorder(),
                child: const Padding(
                  padding:
                      EdgeInsets.all(8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: const Text(
                'Leaf image selected',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSourceButton
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(15),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectionTipsCard
    extends StatelessWidget {
  const _DetectionTipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons
                    .tips_and_updates_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'For better results',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _TipRow(
            text:
                'Use a clear and focused leaf image.',
          ),
          _TipRow(
            text:
                'Make sure the affected area is visible.',
          ),
          _TipRow(
            text:
                'Avoid very dark or blurry photos.',
          ),
        ],
      ),
    );
  }
}

class _TipRow
    extends StatelessWidget {
  final String text;

  const _TipRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 6,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
                EdgeInsets.only(top: 5),
            child: Icon(
              Icons.circle,
              size: 5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight:
                    FontWeight.w500,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiseaseResultScreen
    extends StatelessWidget {
  final File image;
  final DiseaseDetectionResult result;

  const DiseaseResultScreen({
    super.key,
    required this.image,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final bool healthy =
        result.isHealthy;

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Disease Result',
        ),
        backgroundColor:
            AppColors.background,
        foregroundColor:
            AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 230,
                clipBehavior:
                    Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color:
                        AppColors.border,
                  ),
                ),
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      AppColors.cardGreen,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color:
                        AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration:
                          BoxDecoration(
                        color: healthy
                            ? AppColors
                                .primary
                            : AppColors
                                .primary,
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        healthy
                            ? Icons
                                .check_circle_outline
                            : Icons
                                .health_and_safety_outlined,
                        color:
                            Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      healthy
                          ? 'Plant Appears Healthy'
                          : 'Disease Detected',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w900,
                        color: AppColors
                            .textPrimary,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      result.diseaseName,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                        color: AppColors
                            .primary,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      result.cropName,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ConfidenceCard(
                confidence:
                    result.confidence,
              ),
              const SizedBox(height: 14),
              _InformationCard(
                icon:
                    Icons.info_outline_rounded,
                title: 'Description',
                text:
                    result.description,
              ),
              const SizedBox(height: 12),
              _InformationCard(
                icon:
                    Icons.medical_services_outlined,
                title: 'Treatment',
                text:
                    result.treatment,
              ),
              const SizedBox(height: 12),
              _InformationCard(
                icon:
                    Icons.shield_outlined,
                title: 'Prevention',
                text:
                    result.prevention,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color:
                        AppColors.border,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Icon(
                      Icons
                          .info_outline_rounded,
                      size: 19,
                      color:
                          AppColors.primary,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'This result is an AI-based image assessment. Confirm important crop-management decisions with a qualified agricultural professional.',
                        style:
                            TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          fontWeight:
                              FontWeight.w500,
                          color: AppColors
                              .textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceCard
    extends StatelessWidget {
  final double confidence;

  const _ConfidenceCard({
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final double percentage =
        confidence <= 1
            ? confidence * 100
            : confidence;

    final double progress =
        percentage.clamp(0.0, 100.0) / 100.0;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .analytics_outlined,
                size: 21,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Confidence',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            child:
                LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor:
                  AppColors.border,
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InformationCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            text,
            style:
                const TextStyle(
              fontSize: 11.5,
              height: 1.5,
              fontWeight:
                  FontWeight.w500,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}