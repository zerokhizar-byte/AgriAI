# Data and Privacy Notes

## Scope

AgriAI includes mobile features that may handle account information, user-selected images, location, device notifications, and user-entered farm data. The exact data collected depends on which features are enabled and how the Firebase project is configured.

## Developer responsibilities

- Collect only data required for a clearly explained feature.
- Explain why permissions such as location, camera/gallery, microphone, and notifications are requested.
- Do not commit real user records, credentials, private images, logs, or production database exports.
- Avoid logging authentication tokens, personal identifiers, or sensitive farm records.
- Apply least-privilege Firebase Authentication, Firestore, and Storage rules.
- Define retention and deletion behavior for user-generated data.
- Use secure transport for remote requests and restrict external API keys where supported.

## Model inputs

Images and farm measurements submitted to a model should be handled according to the application's privacy notice and the configured processing path. Do not assume that data is processed locally unless the implementation for that feature confirms it.

## Before public release

Publish a clear privacy policy that identifies:

- Data categories collected.
- Purpose and legal basis for collection where applicable.
- Whether processing is local or sent to a backend or third party.
- Retention and deletion periods.
- Third-party services and analytics.
- User contact and data-rights request process.

This document is developer guidance, not a public privacy policy or legal advice.
