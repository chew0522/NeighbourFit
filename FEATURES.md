# FEATURES.md: what NeighbourFit does today

Single list of every feature in the app as it is now. Updated 19 Oct 2026.
Where a feature came from or why it exists: `DECISIONS.md`. Original spec: `teammate md/PRD.md`.

**Status key:** built = code written, analyzer clean and unit tests pass. Only the first screen of the app has been seen on the emulator, so treat every "built" item as not yet walked through on a device. "mock" = simulated on purpose (search the code for `// MOCK:`).

---

## 1. Account and sign-in
| Feature | Status | Notes | Code |
|---|---|---|---|
| Log in with email and password | built | Accounts stored on the device, password salted and hashed | `lib/features/auth/auth_screen.dart`, `lib/data/local/auth_repository.dart` |
| Sign up (email, password, confirm, resident code) | built | Continues into the profile wizard; account is created at the end | same |
| Resident code check | built | Seeded codes, for example `NF-2026` | `assets/seed/locations.json` |
| Forgot password | stub | Shows "not available in this prototype" | `auth_screen.dart` |
| Preset accounts for the team | built | Tap the logo 5 times on the login page, or Settings > Demo tools | `lib/features/auth/preset_accounts.dart` |
| Log out | built | Drawer and settings | `lib/features/shell/app_drawer.dart` |

## 2. Profile
| Feature | Status | Notes | Code |
|---|---|---|---|
| 5-step profile wizard | built | Nickname, avatar colour, age group (starts at 18-29, so everyone is 18+), community, sports, level, times, languages, gender, age preference, emergency contact name (optional). Nothing is preselected and every choice is required. | `lib/features/onboarding/wizard_screen.dart` |
| Edit profile | built | Same wizard, prefilled | same |
| Per-field Public / Private pill toggles (Public = everyone, Private = only me) | built | Age group, gender, level, usual times; knob left with "Private", knob right with "Public"; one short legend line | `lib/features/profile/settings_screen.dart` |
| Neighbour profile page | built | Avatar, bio line, counts, tabs (Posts, Meetups, Lending), tags that respect privacy, "why you may like them", "you're both going to", Message button, Report, Block. No add-friend. | `lib/features/people/user_profile_screen.dart` |
| Block and unblock | built | Hides their posts and removes them from matching and suggestions | settings, profile page, chat |

## 3. Home
| Feature | Status | Notes | Code |
|---|---|---|---|
| Top bar: menu (left), tabs (middle), search (right) | built | TikTok-style | `lib/features/feed/feed_screen.dart` |
| Tabs: For You, Equipment, Meetup | built | Swipe or tap. New tabs are added in `FeedFilter` | `lib/state/app_state.dart` |
| Feed from your own community, newest first | built | Shows the last 7 days; upcoming meetups always show; "Show earlier posts" adds 7 days | same |
| Post types: workout, healthy meal, meetup, equipment | built | Cards have at most 2 buttons; tap opens the detail page | `lib/features/feed/post_card.dart` |
| Post detail pages for workout, meal and equipment | built | Gradient header with the type's icon; photo as a card (tap to zoom); text, place and comments cards; fixed action bar (Cheer / Next time together / Borrow). Equipment adds a status chip and a "How borrowing works" panel. |
| Meetup page | built | Photo or gradient header, when and where cards, spots meter, member chips, organiser, fixed join bar | `lib/features/feed/post_detail_screen.dart` |
| Left drawer | built | Profile, Points & rewards, My equipment, Privacy & settings, Log out | `lib/features/shell/app_drawer.dart` |
| Floating rounded bottom bar | built | Home, Messages, ＋ (raised), Challenges, Me | `lib/features/shell/home_shell.dart` |

## 4. Create (＋)
| Feature | Status | Notes | Code |
|---|---|---|---|
| Full create page with a word strip at the bottom | built | Workout, Meals, Meetup, Equipment. Selected word centred, others fade at the edges. Typed text is kept when switching. | `lib/features/compose/create_screen.dart` |
| Share a workout | built | Sport, place, text | `lib/features/compose/compose_forms.dart` |
| Share a healthy meal | built | Healthy meals only | same |
| Start a meetup | built | Sport, calendar date, time picker, public place. More options: title, max people, level, note, Safe buddy, Accessibility-friendly. Auto title like "Morning run". | `lib/features/compose/meetup_form.dart` |
| Lend equipment | built | Item name and note | `compose_forms.dart` |
| Date and time pickers | built | Past dates greyed out; earlier times today refused | `lib/widgets/date_time_field.dart` |
| Optional photo on every post (camera or gallery, change or remove) | built | Saved on the device | `lib/widgets/photo_field.dart` |
| Photos on Home cards and post detail, tap to open a zoomable full-screen viewer | built | Pinch, drag, double-tap | `lib/widgets/post_photo.dart` |
| Seed photos from `post_pic/` matched to posts by file name | built | `p-s1.jpg` goes to `p_s1` | `lib/data/seed_loader.dart` |

## 5. Meetups
| Feature | Status | Notes |
|---|---|---|
| "I'm in" with Undo (about 4 s) | built | Joins immediately, +20 points once per meetup |
| Leave | built | Detail page or chat menu |
| Capacity: Full and Ended states | built | |
| Group chat created on the first "I'm in" | built | Read-only 3 hours after the meetup starts |
| Safe buddy and Accessible tags | built | |
| "I'm home safe" button | **not built** | |
| Waitlist, check-in, "We met" | **not built** | |

## 6. Social
| Feature | Status | Notes |
|---|---|---|
| Cheer | built | Counts visible only to the poster |
| "Next time together" | built | Poster sees names and can message them. mock: two neighbours react a few seconds after you post. |
| Comments | built | |
| @mentions | built | Bold green text; @ button in the comment bar picks a neighbour |

## 7. Messages
| Feature | Status | Notes | Code |
|---|---|---|---|
| DMs and meetup group chats in one list | built | Sorted by latest message | `lib/features/chat/messages_screen.dart` |
| Cheers page (heart) | built | Who cheered your posts | `lib/features/chat/activity_screens.dart` |
| Mentions page (@) | built | Posts and comments mentioning you | same |
| Comments page | built | Comments on your posts | same |
| Report and Block | built | Report is a mock | `lib/features/chat/chat_screen.dart` |
| Warning before sharing a phone number or address | built | | `lib/services/privacy_guard.dart` |
| Neighbour replies | mock | Canned messages | `lib/state/app_state.dart` |

## 8. Search
| Feature | Status | Notes |
|---|---|---|
| Search posts and neighbours in your community | built | Matches titles, text, sport, place, name |
| Try-searching chips | built | |
| Neighbours you may like | built | Full-width rows with reasons; tap opens their profile. Scored on sport 35, time 20, age 20, distance 15, level and language 10. No AI call. |

Code: `lib/features/search/search_screen.dart`, `lib/services/people_matcher.dart`.

## 9. Challenges
| Feature | Status | Notes |
|---|---|---|
| Challenges tab with 5 challenges per community | built | 10,000 Steps, Weekend Walking, Neighbourhood Cycling, 30 Active Minutes, Splash Together Pool |
| A different reward for each | built | Yoga session, breakfast picnic, bike service day, 50 trees planted, family pool day |
| Join, daily check-in (+10 points), enter your own amount | built | One check-in per day |
| Shared progress only, no rankings | built | |
| Reward locked or unlocked | built | "Fill the closest challenge" demo shortcut in settings |
| Admin or developer screen to create challenges | **not built** | Challenges are seeded |

Code: `lib/features/challenges/`.

## 10. Equipment sharing
| Feature | Status | Notes |
|---|---|---|
| Borrow request | built | Creates a request and a chat with the owner |
| Loan statuses: requested, approved, picked up, returned (plus declined, cancelled) | built | |
| Me > My equipment | built | Requests for your items (Approve, Decline, Mark picked up, Mark returned), items you lend, items you borrow |
| Owner approval | mock | A seeded owner approves your request after about 4 seconds |

Code: `lib/features/profile/my_equipment_screen.dart`, `lib/state/app_state.dart` (`LoansNotifier`).

## 11. Points and rewards
| Feature | Status | Notes |
|---|---|---|
| Points: +20 per meetup joined, +10 per challenge check-in | built | |
| Page with a small bottom bar: Rewards, Vouchers, History | built | Points chip in the top bar |
| Rewards tab: points, community rewards (swipe row, tap opens the challenge), voucher store below | built | 6 vouchers from local businesses with price tags |
| Vouchers tab: wallet of redeemed vouchers only, with codes | built | Empty state offers "Browse the store"; count badge on the icon |
| Redeem | mock | Generates a local code; no merchant system |
| History tab: every earn and spend with totals | built | Needs the points ledger; demo accounts are seeded with history |

Code: `lib/features/profile/rewards_screen.dart`, `lib/state/app_state.dart` (`PointsNotifier`).

## 12. AI assistant
| Feature | Status | Notes | Code |
|---|---|---|---|
| Floating bubble above every screen | built | Draggable, snaps to the edge, hidden while the keyboard is open | `lib/features/assistant/assistant_bubble.dart` |
| Tap: bubble vanishes and the window grows out of it; tap outside: it shrinks back | built | | `assistant_dialog.dart` |
| Understands plain English | built, **live call untested** | DeepSeek turns the sentence into JSON | `lib/services/ai_service.dart` |
| Offline keyword fallback | built, tested | Used with no key, no network or a bad reply | `lib/services/keyword_parser.dart` |
| Finds the top 3 meetups, equipment, or the challenges | built, tested | Hard filters then weighted score. The AI never ranks. | `lib/services/matching_engine.dart` |
| Result cards with a reason and an "I'm in" or "Borrow" button | built | "Search again" button | `assistant_dialog.dart` |
| Searches the whole township | built | With one seeded residence this is the same as your residence | |
| Logs recommendations and what you did next | built | For tuning the weights later | `lib/state/app_state.dart` |
| Find people, search posts, answer questions about you, remember the conversation | **not built** | | |
| Take actions (create a meetup) | **not built, on hold** | `DECISIONS.md` held items | |

## 13. Look and branding
| Feature | Status | Notes |
|---|---|---|
| Colours | built | Warm leaf green primary, light warm yellow highlights, cream background |
| Logo on the login page and in the drawer | built | `lib/widgets/app_logo.dart` |
| Phone home-screen icon | built | Generated into Android; reinstall the app to see it |
| Launch screen | built | Logo as a rounded square on cream |

## 14. Data and settings
| Feature | Status | Notes |
|---|---|---|
| Everything stored on the device | built | No server |
| Seed data with dates relative to today | built | One residence (Lakeside Residences), 20 neighbours, 39 posts with 18 photos, 5 challenges |
| Reset demo data | built | Settings > Demo tools. Also clears local accounts. |
| Switch to a preset account | built | Settings > Demo tools |

---

## Not built yet (summary)
"I'm home safe" · "We met" · meetup waitlist and check-in · AI that finds people, searches posts or takes actions · admin or developer dashboard · any server backend · push notifications.

## Mocked on purpose (summary)
Neighbour chat replies · borrow approvals · "next time together" reactions · voucher codes · Report · forgot password.
