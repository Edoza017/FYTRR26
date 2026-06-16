# FYTRR Release Blockers

## Must Complete Before App Store Submission

1. Add production Yelp API key.
   - Current placeholder: `YOUR_YELP_API_KEY`
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

5. Archive with Apple signing.
   - Use a physical device or `Any iOS Device`.
   - Upload through Xcode Organizer.

## Already Completed

- GitHub PR merged into `main`.
- Local simulator build succeeded.
- AI Coach is hidden from the release navigation.
- App Store metadata draft prepared.
- Privacy nutrition label draft prepared.
- App Review notes prepared.
- TestFlight test plan prepared.

