# FYTRR TestFlight Plan

## Internal Testers
Start with 3-5 internal testers.

Required test flow:
1. Install fresh build.
2. Sign in with Apple.
3. Sign out.
4. Create account with email/password.
5. Complete profile setup.
6. Allow location.
7. Confirm Home loads.
8. Open Map.
9. Use map filters and search.
10. Open restaurant card.
11. Toggle meal reminders.
12. Add/change profile photo.
13. Relaunch app and confirm profile persists.

## External Testers
After internal pass, invite 20-50 external testers.

Ask testers to report:
- Sign-in failures
- Empty states
- Location permission confusion
- Map readability issues
- Restaurant card readability
- Crashes or hangs
- Anything that feels too slow

## Go / No-Go Criteria
Go:
- Build installs cleanly.
- Sign in works.
- Profile persists.
- Home and Map work with and without location.
- Restaurant cards are readable.
- No AI Coach entry point is visible.
- No crash in a 10-minute normal-use session.

No-Go:
- Placeholder API key appears to users in production copy.
- Sign in fails for new users.
- App requires location with no fallback.
- Map is blank with no useful empty state.
- App crashes during onboarding or map use.

