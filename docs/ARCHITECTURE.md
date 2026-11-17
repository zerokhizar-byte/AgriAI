# AgriAI Architecture Overview

## Purpose

AgriAI is a Flutter mobile application that brings agriculture-oriented screens, on-device machine-learning inference, and Firebase-backed application services into one codebase.

This document describes the high-level organization visible in the repository. It is not a guarantee that every screen or integration is production-ready.

## Application layers

### Presentation

The `lib/screens/` directory contains feature screens such as disease detection, yield prediction, weather, recommendations, profile, settings, and authentication.

The `lib/widgets/` directory contains reusable interface components. Navigation is organized under `lib/navigation/`.

### Core and services

The `lib/core/` directory contains shared application foundations such as themes and service code. Feature services should isolate data access, model invocation, and other business logic from presentation widgets.

### Machine-learning assets and inference

The `assets/models/` directory is used for packaged model assets and associated metadata. The disease-detection service loads an ONNX model and a JSON class-name mapping, preprocesses an image, executes inference, and converts the output into a feature result.

Keep training-time and mobile inference preprocessing identical. A model file, class-index mapping, and preprocessing configuration must be versioned and validated together.

### Firebase and platform integrations

Firebase packages are declared in `pubspec.yaml`. Actual availability depends on platform configuration, enabled Firebase products, provider settings, and backend security rules.

Do not place administrative credentials or privileged secrets in the mobile application.

## Runtime data flow

1. The user opens a feature from the application navigation.
2. The feature screen validates user input or selected media.
3. A feature service performs the operation, such as image preprocessing and ONNX inference.
4. The service returns a typed result or an error.
5. The screen displays the result and any relevant limitations.

## Configuration boundaries

- Flutter package and asset declarations: `pubspec.yaml`.
- Android platform configuration: `android/`.
- Firebase client initialization: platform-specific configuration and FlutterFire options.
- Model files and class mapping: `assets/models/`.

## Design principles

- Keep UI and business logic separated.
- Validate inputs before inference or remote requests.
- Surface errors clearly instead of silently returning fabricated values.
- Treat model output as an estimate, not a guaranteed agricultural outcome.
- Never commit secrets, private user data, or datasets without appropriate rights.
