# FYTRR Store Release Checklist

See `AppStoreRelease/` for App Store metadata, review notes, privacy label draft, TestFlight plan, and current blockers.

## Release scope
- AI Coach is hidden for this release.
- Home is simplified to daily targets, top nearby meals, refresh, and map access.
- Apple Health / readiness is not user-facing in this release.
- WHOOP is hidden/disabled in this release.

## Required in Xcode before archive
1. Target `FYTRR 2026` -> `Signing & Capabilities`
- Confirm Sign in with Apple is enabled.
- Do not enable HealthKit for this release unless the readiness UI returns.

2. Target `FYTRR 2026` -> `Info`
- Confirm `Privacy - Location When In Use Usage Description` exists.
- Set `YELP_API_KEY` to a valid production key before submitting.
- Confirm no OpenAI API key is bundled while AI Coach is hidden.

3. Target `FYTRR 2026` -> `General`
- Bump `Build` number for each upload.
- Confirm app icon and display name are final.

## Archive + Upload
1. Select `Any iOS Device (arm64)`.
2. `Product` -> `Archive`.
3. In Organizer: `Distribute App` -> `App Store Connect` -> `Upload`.

## App Store Connect checks
- Add screenshots for onboarding, Home, Fuel, and Map.
- Fill privacy nutrition labels for account, location, and restaurant search behavior.
- Add support URL, marketing URL if available, privacy policy URL, description, keywords, and review notes.
- Add beta/review notes explaining location is used to find nearby meal options.
- Use `AppStoreRelease/APP_STORE_METADATA.md` for listing copy.
- Use `AppStoreRelease/APP_REVIEW_NOTES.md` for reviewer notes.
- Use `AppStoreRelease/PRIVACY_NUTRITION_LABEL.md` as the privacy answer draft.

## Pre-submit sanity tests
- Sign in works.
- Profile setup completes.
- Location permission prompt appears only when needed.
- Home loads without AI Coach visible.
- Fuel list loads real restaurants when `YELP_API_KEY` is valid.
- Map opens, pins render, list sheet opens, and menu/order buttons work.
- App still behaves acceptably with sample data if Yelp is unavailable.
