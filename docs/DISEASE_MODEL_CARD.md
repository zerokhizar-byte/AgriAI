# Disease Detection Model Card

## Model purpose

The AgriAI disease-detection feature is designed to classify selected crop-leaf images into one of the classes listed in `assets/models/class_names.json`.

## Implementation visible in the repository

- Runtime format: ONNX
- Flutter inference package: `flutter_onnxruntime`
- Image input size: 224 × 224 pixels
- Color channels: RGB
- Input normalization: ImageNet mean and standard deviation
- Output mapping: 19 class names in `assets/models/class_names.json`

The current class mapping covers selected diseases and healthy-leaf classes for corn, pepper, potato, and tomato.

## Intended use

Use the output as an initial screening aid or educational demonstration. It is not a substitute for diagnosis by an agricultural extension officer, plant pathologist, or other qualified expert.

## Out-of-scope use

- Automated pesticide or fungicide application without expert review.
- Guaranteed diagnosis across all crop species and cultivars.
- Diagnosis from non-leaf images or images outside the model's training domain.
- Decisions involving crop insurance, finance, or regulatory compliance without independent validation.

## Known limitations

Predictions may be affected by lighting, focus, camera quality, leaf age, background clutter, disease severity, mixed infections, and differences between training images and field conditions.

The softmax score shown by an application is a model score, not necessarily a calibrated probability of correctness.

## Evaluation status

The repository documentation does not claim independently validated field accuracy. A test against images drawn from the same source dataset or a split derived from training data does not establish real-world generalization.

Before operational deployment, evaluate on a separately collected, representative field dataset. Report per-class precision, recall, F1-score, confusion matrix, calibration, and performance across devices and field conditions.

## Human oversight

Users should seek expert confirmation before taking crop-treatment decisions. Treatment guidance must also follow local agricultural recommendations and product labels.
