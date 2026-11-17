# Contributing to AgriAI

Thank you for considering a contribution. This project is developed in the open, and focused, well-documented contributions are welcome.

## Before you start

- Read the [README](README.md) to understand the project and its current limitations.
- Check existing issues and pull requests before starting duplicate work.
- For a substantial change, open an issue first to discuss the proposed approach.
- Do not include credentials, private keys, personal information, proprietary datasets, or unlicensed assets.

## Development setup

1. Install a Flutter SDK compatible with the constraints in `pubspec.yaml`.
2. Clone the repository and enter its directory.
3. Run `flutter pub get`.
4. Configure Firebase locally if the feature you are working on requires it.
5. Run the app on an emulator or physical device.

## Code guidelines

- Follow the Dart and Flutter style conventions used in the codebase.
- Prefer small, focused changes over unrelated refactoring.
- Use clear names and add comments where the intent is not obvious.
- Handle loading, empty, and error states in user-facing features.
- Validate external input and avoid logging sensitive information.
- Keep model preprocessing consistent with the preprocessing used during training.
- Do not describe model metrics as real-world accuracy unless independently validated.

## Before opening a pull request

Run:

```bash
dart format .
flutter analyze
flutter test
```

If a command cannot be run, state that clearly in the pull request. Include relevant device/OS details and reproducible test steps for UI or platform changes.

## Pull requests

A useful pull request includes:

- A concise description of the problem and solution.
- Related issue links, if applicable.
- Screenshots or a short recording for UI changes.
- Tests performed and their results.
- Any Firebase, model, dataset, permission, or configuration changes.
- Known limitations and follow-up work.

By submitting a contribution, you agree that your contribution is provided under the repository's MIT License, unless a different written agreement is made with the maintainers.
