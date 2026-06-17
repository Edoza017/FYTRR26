# FYTRR Upload Result

## App Store Connect Upload

Status: Build 6 archived successfully; App Store Connect upload blocked by local Xcode account credentials

Latest uploaded build:
- Version: `1.0`
- Build: `5`
- Uploaded: `2026-06-16`
- Yelp API key: active key injected at archive time; key was not committed to GitHub.
- Status: uploaded successfully and processing in App Store Connect.

Upload command completed:
- `xcodebuild -exportArchive`
- Destination: App Store Connect upload
- Archive path: `/tmp/FYTRR-2026-build5.xcarchive`

Apple response:
- Uploaded package is processing.
- Upload succeeded.

## Validation Completed

- Simulator build succeeded.
- iOS archive succeeded for build `5`.
- Archive `1.0` build `5` verified with non-placeholder `YELP_API_KEY` present in the built app plist.
- App Store Connect export succeeded.
- App Store Connect upload succeeded.
- iOS archive succeeded for version `1.0` build `6` at `/tmp/FYTRR-2026-build6.xcarchive`.
- Archive `1.0` build `6` verified with non-placeholder `YELP_API_KEY` present in the built app plist.

## Build 6 Upload Attempt

- Attempted: `2026-06-16 23:16 PDT`
- Version: `1.0`
- Build: `6`
- Archive path: `/tmp/FYTRR-2026-build6.xcarchive`
- Included latest app updates: FYTRR Credits v1, Fuel readiness move, and improved Apple Maps directions fallback.
- Upload/export blocker: Xcode account credentials are invalid locally. Xcode reported the saved App Store Connect account is missing `Xcode-Username` in Keychain.
- Next action: Open Xcode, go to Settings > Accounts, remove/re-add or re-authenticate the Apple Developer account, then rerun App Store Connect upload for `/tmp/FYTRR-2026-build6.xcarchive`.

## Upload Warnings

The upload reported missing dSYM files for several third-party Firebase/grpc related frameworks:
- `FirebaseFirestoreInternal.framework`
- `absl.framework`
- `grpc.framework`
- `grpcpp.framework`
- `openssl_grpc.framework`

These warnings do not block the uploaded build, but crash symbolication for those third-party frameworks may be incomplete. Revisit package dSYM handling before a major production launch if crash diagnostics become important.

## Still Required In App Store Connect

- Wait for build processing to finish.
- Attach the processed build to app version `1.0`.
- Add screenshots.
- Add privacy policy/support URLs.
- Complete privacy nutrition labels.
- Complete age rating.
- Add review notes.
- Run TestFlight or submit for review.
