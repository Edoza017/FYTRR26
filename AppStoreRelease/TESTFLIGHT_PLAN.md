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
11. Tap Go and confirm Apple Maps opens the expected restaurant destination.
12. Mark daily fuel and confirm FYTRR Credits increase.
13. Open Profile and confirm the FYTRR Credits card is understandable.
14. Toggle meal reminders.
15. Add/change profile photo.
16. Relaunch app and confirm profile persists.

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
- Whether FYTRR Credits feel motivating or confusing
- Whether Apple Maps directions open the correct restaurant

## Go / No-Go Criteria
Go:
- Build installs cleanly.
- Sign in works.
- Profile persists.
- Home and Map work with and without location.
- Restaurant cards are readable.
- No AI Coach entry point is visible.
- FYTRR Credits are visible but clearly positioned as future meal rewards.
- Go opens Apple Maps with the expected restaurant destination.
- No crash in a 10-minute normal-use session.

No-Go:
- Placeholder API key appears to users in production copy.
- Sign in fails for new users.
- App requires location with no fallback.
- Map is blank with no useful empty state.
- Directions regularly open the wrong restaurant.
- FYTRR Credits appear to promise immediate cash or DoorDash redemption.
- App crashes during onboarding or map use.
