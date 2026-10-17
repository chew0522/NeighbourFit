
## 9. Colour change (17 Oct 2026)

Option A chosen: the bright orange accent is replaced by a muted terracotta so it sits better next to the green.

| Token | Before | Now |
|---|---|---|
| `kAccent` | `#FF8A4C` | `#E07A5F` |
| `kBackground` | `#FAF7F2` | `#F7F1E8` |

Other tokens are unchanged. Dark text on the accent stays (never white). This overrides the colour values in `teammate md/CLAUDE.md` section 6; the role rules (green = health and structure, accent = people and interaction) still apply.

## 10. TikTok-style home and navigation (17 Oct 2026)

Owner request. Overrides the bottom bar and filter chips in `teammate md/PRD.md` section 6.2.

- **Home top bar:** hamburger (opens a left drawer) on the left, horizontally scrollable tabs in the middle, search on the right. Tabs are **For You** (default), **Equipment**, **Meetup**. More tabs can be added by adding a value to `FeedFilter` in `lib/state/app_state.dart`. Swiping sideways also changes tab.
- **For You** shows everything from your community (workouts, meals, meetups, equipment). The old "Shares" chip and the pinned challenge card are removed from the feed.
- **Drawer:** Profile, Points & rewards, My equipment, Privacy & settings, Switch account.
- **Search:** posts and neighbours in your own community (not the whole township).
- **Bottom bar:** floating, rounded, 5 slots: Home, Messages, ＋, Challenges (trophy), Me. The ＋ still opens the create sheet.
- **Challenges tab:** replaces the pinned card. Five challenges per community, each with its own reward: 10,000 Steps (yoga session), Weekend Walking (breakfast picnic), Neighbourhood Cycling (bike service day), 30 Active Minutes (50 trees planted), Splash Together Pool (family pool day). Targets and progress are scaled per community. They are still seeded, with no admin screen. Only community totals are shown.
- **App bars** are now cream with dark text on every screen.
- Seed version bumped to 3: the first launch after this change reseeds local demo data.

## 11. Neighbours you may like moves to Search; neighbour profile page (17 Oct 2026)

Supersedes section 2.1's placement ("top of the Messages tab") and the "Say hi" button.

- **Where:** the suggestions now sit at the top of the Search screen (search icon on Home), shown as full-width rectangular rows with reasons. A small cross on a row means "Not now". The Messages tab is back to chats only.
- **Tap a neighbour** (in suggestions, search results, a post's author, or a meetup's member list) to open their **profile page**.
- **Profile page:** large avatar, nickname, community and join month, a one-line bio built from level and sports, counts for Posts, Meetups and Lending, tabs for each, tags (age group, usual times, languages, accessibility) that respect the person's privacy settings, "why you may like them" chips, and a "You're both going to" card for upcoming meetups you share.
- **Only action: Message.** No follow or add-friend. A menu offers Report and Block. On your own profile the button is Edit profile.
- The recommendation log now records `messaged` when you message someone from their profile, if they are someone the app would suggest.

## 12. Bigger ＋ button and AI bubble behaviour (17 Oct 2026)

- **＋ button:** 70 px (was 54), rounded square with a cream ring and shadow, raised about 22 px above the floating bar.
- **AI bubble:** like the iPhone assistive-touch ball. Tap: the bubble shrinks away and the chat window grows out of the bubble's position. Tap anywhere on the dimmed area outside the window (or the ✕): the window shrinks back into the bubble, which pops back in with a small overshoot. The bubble is still draggable and snaps to the nearest edge with a short glide.

## 13. Messages tab (17 Oct 2026)

- The tab keeps the title "Messages"; the extra "Chats" heading and the "Direct" label are removed. Group chats keep their group icon.
- Three icons sit above the list:
  - **Cheers** (heart): who cheered your posts. Cheer counts stay visible only to the poster, so this page is the only place they show.
  - **Mentions** (@): posts and comments where someone wrote `@YourNickname`. Mentions are bold green in posts and comments, and the comment bar has an @ button to pick a neighbour.
  - **Comments** (speech bubble): comments neighbours left on your posts.
- Seed version 4: adds posts for the demo accounts and a few comments with mentions, so these pages are not empty on first run.
