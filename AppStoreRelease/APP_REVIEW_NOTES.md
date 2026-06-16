# FYTRR App Review Notes

Paste the relevant parts into App Store Connect review notes.

## Test Account
If Apple cannot use Sign in with Apple during review, create a reviewer email/password account and add it here before submitting.

- Email: TODO
- Password: TODO

## Review Notes
FYTRR is a nutrition and nearby meal discovery app. Location access is used to find nearby restaurant and meal options. Users can still view fallback content if live restaurant data is unavailable.

AI Coach is not part of the user-facing release experience in version 1.0. Any AI Coach code path is hidden from navigation and should not be evaluated as a live feature for this submission.

The app does not provide medical advice. Nutrition and restaurant guidance is informational and intended for general wellness and meal planning.

## Permission Notes
- Location When In Use: used to show nearby restaurant and meal options.
- Notifications: optional meal reminders only after user opt-in.
- Photos: optional profile photo selection only after user action.

## External Services
- Firebase is used for authentication/profile storage.
- Yelp API is used for live nearby restaurant search when a production API key is configured.
- OpenAI live AI is not enabled for this release.

## Known Release Configuration Requirement
Before submission, replace `YOUR_YELP_API_KEY` with the production Yelp API key in the app target settings.

