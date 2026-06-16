# FYTRR Release Blockers

## Must Complete Before App Store Submission

1. Confirm Firebase production project.
   - Verify `GoogleService-Info.plist` is the production FYTRR Firebase app.
   - Confirm Authentication providers are enabled.
   - Firestore is not currently used for profile sync in this release.

2. Create public web URLs.
   - Privacy Policy URL
   - Support URL
   - Optional Marketing URL

3. Confirm Apple Developer capabilities.
   - Bundle ID: `com.edwinmendoza.FYTRR-2026`
   - Sign in with Apple enabled.
   - Push notifications only if reminder implementation requires production push entitlement. Local notifications do not.
   - HealthKit enabled for optional Apple Health fuel balance.

4. Complete App Store Connect listing.
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
- App Store Connect upload succeeded for version `1.0` build `3`.
- App Store Connect upload succeeded for version `1.0` build `5` with location fallback and Apple Health fuel balance fixes.
- Active Yelp API key validated, injected at archive time, and not committed to GitHub.
- App Info.plist files now read `YELP_API_KEY` from a build setting so release archives can inject the key safely.
- AI Coach is hidden from the release navigation.
- App Store metadata draft prepared.
- Privacy nutrition label draft prepared.
- App Review notes prepared.
- TestFlight test plan prepared.
