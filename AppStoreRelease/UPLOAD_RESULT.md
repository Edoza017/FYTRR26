# FYTRR Upload Result

## App Store Connect Upload

Status: Uploaded successfully

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
- iOS archive succeeded.
- Archive `1.0` build `5` verified with non-placeholder `YELP_API_KEY` present in the built app plist.
- App Store Connect export succeeded.
- App Store Connect upload succeeded.

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
