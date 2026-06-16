# FYTRR Privacy Nutrition Label Draft

Use this as a starting point for App Store Connect privacy answers. Verify it against the final production configuration before submitting.

## Data Collected

### Contact Info
Likely collected:
- Email address

Purpose:
- App functionality
- Account management

Linked to user:
- Yes

Tracking:
- No

### User Content / Profile Data
Likely collected:
- Name
- Fitness/nutrition profile details entered by the user
- Goal, activity level, meals per day, and related preferences
- Optional profile photo

Purpose:
- App functionality
- Personalization

Linked to user:
- Yes

Tracking:
- No

### Location
Likely collected:
- Precise or approximate location while using the app

Purpose:
- App functionality
- Nearby restaurant and meal discovery

Linked to user:
- Review final implementation before answering. If location is only used transiently for nearby search and not stored with the account, mark accordingly in App Store Connect.

Tracking:
- No

### Health / Fitness
For version 1.0:
- Apple Health / readiness is not user-facing.
- If HealthKit remains disabled and no health data is read, do not claim Health data collection.
- If HealthKit is re-enabled before submission, disclose health and fitness data accurately.

### Identifiers / Diagnostics
Firebase and Apple platform services may collect identifiers or diagnostics depending on enabled configuration.

Review before submission:
- Firebase Authentication
- Firebase Firestore
- Firebase Analytics, if enabled later
- Crash reporting, if enabled later

## Tracking
Current intended answer:
- No, this app does not track users across apps and websites owned by other companies.

## Privacy Policy Must Say
- What account/profile data FYTRR collects
- Why location is requested
- How restaurant search providers are used
- Whether data is shared with Firebase/Yelp
- How users can request account deletion or support
- That FYTRR is not medical advice

