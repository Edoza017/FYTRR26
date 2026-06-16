# FYTRR Release Blockers

## Must Complete Before App Store Submission

1. Add production Yelp API key.
   - Current placeholder: `YOUR_YELP_API_KEY`
   - A previously used Yelp Fusion key was found locally, but Yelp rejected it with `TRIAL_EXPIRED`.
   - Upgrade the Yelp developer app or create a new active production key before uploading the replacement build.
   - Affected files/settings:
     - `FYTRR-2026-Info.plist`
     - `FYTRR 2026/FYTRR-2026-Info.plist`
     - `INFOPLIST_KEY_YELP_API_KEY` in the Xcode project settings

2. Confirm Firebase production project.
   - Verify `GoogleService-Info.plist` is the production FYTRR Firebase app.
   - Confirm Authentication providers are enabled.
   - Confirm Firestore rules are production-safe.

3. Create public web URLs.
   - Privacy Policy URL
   - Support URL
   - Optional Marketing URL

4. Confirm Apple Developer capabilities.
   - Bundle ID: `com.edwinmendoza.FYTRR-2026`
   - Sign in with Apple enabled.
   - Push notifications only if reminder implementation requires production push entitlement. Local notifications do not.
   - HealthKit disabled for this release unless Health UI returns.

5. Complete App Store Connect listing.
   - Wait for the uploaded build to finish processing.
   - Add screenshots.
   - Add privacy policy/support URLs.
   - Complete privacy nutrition labels.
   - Complete age rating.
   - Add review notes.

## Already Completed

- GitHub PR merged into `main`.
- Local simulator build succeeded.
- iOS archive succeeded.
- App Store Connect export succeeded.
- App Store Connect upload succeeded.
- AI Coach is hidden from the release navigation.
- App Store metadata draft prepared.
- Privacy nutrition label draft prepared.
- App Review notes prepared.
- TestFlight test plan prepared.
