# PROGRESS.md: build status (working copy)

The teammate's original is in `teammate md/PROGRESS.md` and is untouched. This is the live copy for the Flutter project. Overrides are in `DECISIONS.md`.

Last update: 17 Oct 2026. Status values: `todo` · `built` (code written, analyzer clean) · `verified` (seen working on the emulator).

## 1. How it was checked so far

- `flutter analyze`: no issues.
- `flutter test`: 32 tests pass (matching worked example Aiman about 80.8 and Siti about 50.5, hard filters, dynamic weights, keyword parser, AI output validation, privacy guard, people suggestions).
- Emulator (Android, Medium Phone API 36): the debug app builds, installs and opens on the **Welcome screen** (verified visually).
- **Not yet verified on the emulator:** everything after sign-in. The adb session was interrupted by an "Allow USB debugging" prompt. Walk the demo flows in `teammate md/DEMO_SCRIPT.md` by hand and log any bug in section 4.

## 2. Phase status

| # | Phase | Status |
|---|---|---|
| 1 | Skeleton: theme, 4-slot nav, ＋ sheet, AI bubble, `.env` | built |
| 2 | Data layer: models, repositories, seed JSON with relative dates, reset | built |
| 3 | Feed: cards, 4 chips, pinned challenge, ＋ forms, cheer, comments, Next time together | built |
| 4 | Meetups and chat: I'm in, Undo, Leave, group chat, DMs, report/block, privacy warning, equipment loans | built |
| 5 | AI matching: keyword parser, engine + tests, DeepSeek service, assistant popup, fallbacks | built (live AI call untested: no API key yet) |
| 6 | Polish: onboarding wizard, profile, privacy toggles, rewards, challenge check-in | built |

## 3. Feature checklist (Tier 1 and Tier 2, plus DECISIONS.md additions)

**Tier 1**
- [x] Profile wizard (built)
- [x] Feed with five post types, 4 chips, 7-day window, "Show earlier posts" (built)
- [x] ＋ Share a workout, ＋ Start a meetup with calendar and time pickers (built)
- [x] I'm in: capacity, Open chat, Undo snackbar, Leave (built)
- [x] AI assistant: bubble, popup, parse, filter, score, top 3 cards (built)
- [x] AI fallback with no network or no key (built)

**Tier 2**
- [x] Meetup group chat created on first I'm in (built)
- [x] Next time together, poster-only list (built, mock reactions after 4 s)
- [x] Minimal rewards: points, vouchers, mock redeem, community reward unlock (built)
- [x] Accessibility-friendly tag and needs-accessibility matching (built)
- [x] DMs, report, block, phone/address warning (built)
- [x] Challenge card, join, daily check-in, shared progress (built)
- [x] Healthy meal post (healthy meals only) (built)
- [x] Equipment post, Borrow with loan tracking: requested, approved, picked up, returned (built, mock approval after 4 s)
- [x] Resident code and multi-step onboarding wizard (built)
- [x] Per-field privacy toggles (built)
- [x] Neighbours you may like (top of Messages tab) (built)

**Tier 3 (not built yet)**
- [ ] Safe buddy "I'm home safe" button (the Safe buddy tag and option are built)
- [ ] "We met" confirmation
- [ ] Meetup waitlist and check-in (DECISIONS.md 2.3)

## 3b. TikTok-style home (17 Oct 2026, built, not yet seen on device)
- [x] Top bar: hamburger drawer, scrollable tabs (For You, Equipment, Meetup), search
- [x] Floating rounded bottom bar: Home, Messages, ＋, Challenges, Me
- [x] Challenges tab with 5 challenges and different rewards per community
- [x] Search screen (posts and neighbours)
- [x] Neighbours you may like moved to Search as rectangular rows
- [x] Neighbour profile page (Message only, no add friend)

## 4. Known issues and gaps

| # | Where | Note |
|---|---|---|
| 1 | Photos | Posts have no photo upload yet (`image_picker` not added). Text and place only. |
| 2 | Live AI | Needs `AI_API_KEY` in `.env`. Verify the DeepSeek model name and pricing first. |
| 3 | Demo challenge | One pinned challenge per community. "Fill the community challenge" in Privacy & settings shows the unlocked reward. |
| 4 | Whole app | Only the Welcome screen has been seen on a device. Treat everything else as untested UI. |

## 5. Decisions log

See `DECISIONS.md` for the full list. Added during the build:
- Each community has its own pinned challenge (3 seeded).
- Challenge check-in is limited to once per day.
- The AI bubble hides while the keyboard is open.
- Group chats become read-only 3 hours after the meetup starts.

## 6. Next up

1. Allow USB debugging on the emulator (or test by hand) and walk the demo flows.
2. Fill `AI_API_KEY` in `.env` and test the live assistant, including the fallback with Wi-Fi off.
3. Fix whatever the walkthrough finds, then add Tier 3 items if time allows.
