# Rumbl Project Understanding Guide

## Start Here First (Top 5)

If you only have 30–45 minutes, read these first:

1. `lib/rumbl_web/router.ex` — full route map, auth boundaries, and which LiveViews are public vs protected.
2. `lib/rumbl_web/live/ring_live/index.ex` — central orchestration LiveView for rings, invitations, category management, presence, and video workspace behavior.
3. `lib/rumbl/multimedia.ex` — core business logic for videos, categories, and annotations.
4. `lib/rumbl/rings.ex` — ring lifecycle, memberships, invitations, and access patterns.
5. `lib/rumbl_web/live/ring_live/components/main_content.ex` — the primary user experience (video workspace, annotations, timeline, action controls).

---

## 1) Project Overview

### What this project does

Rumbl is a Phoenix LiveView web application for **group-based video collaboration**. Users create/join “rings” (workspaces), add YouTube videos, and leave timestamped annotations while watching.

### Main problem it solves

It solves the “scattered feedback” problem for video discussions:

- Discussion happens at a specific timestamp, not a generic comment thread.
- Access is scoped to collaborative groups (rings).
- Presence and workspace affordances make collaboration feel live.

### Likely users

- Study groups reviewing educational videos.
- Teams discussing recorded demos/tutorials.
- Communities that want synchronized, timestamped commentary on shared videos.

### Core features and flows

- Authentication and account creation.
- Ring creation, joining by invite code, membership management.
- Ring owner invites users via invitation requests.
- Video CRUD scoped to a ring.
- Category CRUD scoped to a ring.
- Timestamped annotations (add/search/filter/seek/delete own annotations).
- Presence indicators (“Active now” online/offline states).
- Locale switching (`en`, `fil`).

---

## 2) Architecture Overview

### High-level organization

Rumbl follows standard Phoenix context + web-layer architecture:

- **Domain contexts (`lib/rumbl`)**
  - `Rumbl.Accounts` for users/auth checks.
  - `Rumbl.Rings` for workspace and invitation logic.
  - `Rumbl.Multimedia` for videos/categories/annotations.
- **Web layer (`lib/rumbl_web`)**
  - Router and plugs.
  - LiveViews for interactive UI.
  - Controller endpoints for locale/session actions.
- **Persistence**
  - PostgreSQL via Ecto schemas/migrations.
- **Client runtime**
  - Phoenix LiveView + custom JS hooks (YouTube integration, UX interactions).

### Main modules/components

- Runtime boot: `Rumbl.Application`, `RumblWeb.Endpoint`, `Rumbl.Repo`.
- Auth/session: `RumblWeb.Auth`, `RumblWeb.UserLiveAuth`, `RumblWeb.SessionController`.
- Collaboration: `RumblWeb.RingLive.Index` + submodules (`RingManagement`, `Invitations`, `PanelSearch`, `AnnotationSearch`, `RingPresence`, `CategoryManagement`).
- Video workspace behavior: `RumblWeb.VideoLive.Index`, `RumblWeb.VideoLive.Show`, `RumblWeb.VideoLive.Watch`, `RumblWeb.VideoLive.Modal`.

### Data and control flow

1. Browser connects to LiveView socket (`/live`) through `RumblWeb.Endpoint`.
2. Router live sessions mount auth context (`RumblWeb.UserLiveAuth`).
3. LiveView receives events (`phx-click`, `phx-submit`, `phx-change`).
4. LiveView delegates business operations to context modules (`Rumbl.*`).
5. Context modules execute Ecto operations via `Rumbl.Repo`.
6. LiveView updates assigns/streams, pushes events to JS hooks for player interactions.
7. PubSub + Presence synchronize online activity updates.

### Design patterns used

- **Context pattern** (Phoenix idiomatic domain boundaries).
- **LiveView decomposition by behavior modules** (`RingLive.Index` delegates to submodules and shared `VideoState`).
- **Ecto.Multi transactions** for multi-step consistency (`create_ring`, invitation accept flow).
- **Event-driven UI** using LiveView events + JS hooks (`seek_video`, player metrics).
- **Presence topic scoping** by ring IDs.

---

## 3) File and Folder Breakdown

## Major folders

| Folder                 | Purpose                                                                    |
| ---------------------- | -------------------------------------------------------------------------- |
| `lib/rumbl`            | Domain/business contexts, schemas, app supervision, repo and mailer setup. |
| `lib/rumbl_web`        | Router, endpoint, plugs, controllers, LiveViews, UI components, telemetry. |
| `assets`               | Frontend JS hooks, Tailwind CSS, vendor plugins.                           |
| `config`               | Environment-specific runtime/build/server/database configuration.          |
| `priv/repo/migrations` | Database schema evolution.                                                 |
| `test`                 | LiveView/controller tests plus shared fixtures/support helpers.            |

## Important files (responsibility + dependencies)

| File                                                      | Responsibility                                                     | Depends on                                     | Depended on                                        | Why it matters                                          |
| --------------------------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------- | -------------------------------------------------- | ------------------------------------------------------- |
| `mix.exs`                                                 | App metadata, deps, aliases (`setup`, `precommit`, assets tasks).  | Mix/Phoenix tooling                            | Entire build/runtime lifecycle                     | Defines how project is built, tested, and released.     |
| `lib/rumbl/application.ex`                                | OTP supervision tree startup.                                      | Endpoint, Repo, Telemetry, PubSub, Presence    | Runtime boot                                       | Defines service availability and startup order.         |
| `lib/rumbl_web/router.ex`                                 | All HTTP and LiveView routes + auth sessions.                      | Auth/Locale plugs, LiveViews/controllers       | Endpoint dispatch                                  | Single source of truth for navigation/auth boundaries.  |
| `lib/rumbl/accounts.ex`                                   | User retrieval/search/register/update/password auth.               | `Rumbl.Accounts.User`, `Repo`, `Bcrypt`        | Controllers/LiveViews/auth                         | Core identity model and login verification.             |
| `lib/rumbl/rings.ex`                                      | Ring creation/joining, membership checks, invitations.             | Ring schemas, `Repo`, `Ecto.Multi`             | Ring/Video flows, profile access checks            | Encodes collaboration permissions and invite lifecycle. |
| `lib/rumbl/multimedia.ex`                                 | Video/category/annotation CRUD + ring/video searches.              | Multimedia schemas, `Repo`                     | Video/Ring LiveViews                               | Core collaborative content logic.                       |
| `lib/rumbl_web/live/ring_live/index.ex`                   | Main authenticated workspace orchestration.                        | Ring submodules, VideoState, contexts          | `/rings`, `/rings/:ring_id`, `/invitations` routes | Highest-complexity behavioral coordinator in app.       |
| `lib/rumbl_web/live/video_live/index.ex`                  | Video panel workflow + annotation/timeline event handling.         | `Show`, `Watch`, `Modal`, contexts             | `/videos`; reused from RingLive                    | Handles dense user interactions and many events.        |
| `lib/rumbl_web/live/ring_live/components/main_content.ex` | Primary UI rendering of ring workspace and requests panel.         | Helper module + Watch formatter + Live assigns | RingLive template                                  | Converts state into user-visible behavior.              |
| `assets/js/app.js`                                        | LiveSocket init + hooks (`YouTubeSeek`, `AutoGrowTextarea`, etc.). | Phoenix JS libs, topbar, browser APIs          | All LiveView pages                                 | Frontend behavior bridge for realtime UX.               |
| `assets/css/app.css`                                      | App styling system and component classes.                          | Tailwind v4 + DaisyUI plugins                  | All rendered pages                                 | Defines product look/feel and micro-interactions.       |
| `priv/repo/migrations/*`                                  | DB structure for users/rings/videos/invitations/categories.        | Ecto migration runtime                         | Context query assumptions                          | Data model correctness and historical evolution.        |

---

## 4) Code Flow Walkthrough

## Where the app starts

- Build/runtime declaration: `mix.exs` (`mod: {Rumbl.Application, []}`).
- Supervision starts in `Rumbl.Application.start/2` with:
  - telemetry
  - repo
  - pubsub/presence
  - endpoint.
- Requests/LiveView socket enter through `RumblWeb.Endpoint`.

## Flow A: User logs in

1. User opens `/sessions/new` (LiveView form in `SessionLive.New`).
2. Form submits POST `/sessions`.
3. `SessionController.create/2` calls `Accounts.authenticate_by_username_and_pass/2`.
4. On success, `Auth.login/2` sets session `user_id` and redirects `/rings`.

## Flow B: User enters rings workspace

1. Route `/rings` or `/rings/:ring_id` is protected by live session `:authenticated_user` with `UserLiveAuth.ensure_authenticated`.
2. `RingLive.Index.mount/3` initializes UI state and refreshes ring data via `RingManagement.refresh_user_rings_and_video_state/1`.
3. If ring selected, `VideoState.apply_live_action/4` loads ring videos and selected video.
4. `RingPresence.sync_presence_topic/1` subscribes and tracks online state.

## Flow C: Add annotation and seek video

1. User submits annotation form (`phx-submit="add_annotation"`).
2. `VideoLive.Index.dispatch_event/4` delegates to `Watch.add_annotation/3`.
3. `Multimedia.annotate_video/3` inserts annotation.
4. LiveView refreshes annotations and assigns.
5. Timeline marker click sends `select_annotation_from_timeline`; server pushes `seek_video` event.
6. JS hook `YouTubeSeek` receives event and calls YouTube player `seekTo`.

## Flow D: Invite user to ring

1. Owner goes to `/invitations` panel and chooses owned ring.
2. Search users via `Invitations.search_invitees/2` (excludes current members + pending invites).
3. `Invitations.send_invite/2` -> `Rings.send_ring_invitation/3`.
4. Invitee views pending requests and responds (`accept`/`decline`).
5. `Rings.respond_to_ring_invitation/3` updates invitation; on accept uses transaction to insert membership.

## Frontend-backend interaction pattern

- UI actions are primarily LiveView events.
- High-frequency/video-specific behavior is handled via hooks and `push_event/3`.
- Presence updates arrive via PubSub `presence_diff` and refresh online indicators.

---

## 5) Key Components and Functions

## Domain layer

| Module / Function                              | Input                          | Output                             | Side effects / Notes                                                     |
| ---------------------------------------------- | ------------------------------ | ---------------------------------- | ------------------------------------------------------------------------ |
| `Accounts.authenticate_by_username_and_pass/2` | username, password             | `{:ok, user}` or error tuple       | Uses Bcrypt verification + no-user timing protection.                    |
| `Rings.create_ring/2`                          | owner user, ring attrs         | `{:ok, ring}` or changeset error   | Transaction inserts ring + owner membership + generated invite code.     |
| `Rings.join_ring_by_invite/2`                  | user, invite_code              | `{:ok, ring}` / `{:error, reason}` | Membership insertion with duplicate/member checks.                       |
| `Rings.send_ring_invitation/3`                 | inviter, ring_id, invitee_id   | insert result / error atom         | Enforces owner-only invitation and duplicate checks.                     |
| `Rings.respond_to_ring_invitation/3`           | invitee, invitation_id, action | update result                      | Accept path wraps invitation update + membership insert in `Ecto.Multi`. |
| `Multimedia.create_video/2`                    | user, video params             | insert result                      | Associates user and validates URL/ring/category constraints.             |
| `Multimedia.search_videos_for_rings/3`         | ring_ids, query                | list of videos                     | Cross-ring search in global panel modal context.                         |
| `Multimedia.annotate_video/3`                  | user, video_id, attrs          | insert result                      | Persists timestamped annotation.                                         |

## LiveView orchestration layer

| Module / Function                    | What it does                                                                                        |
| ------------------------------------ | --------------------------------------------------------------------------------------------------- |
| `RingLive.Index.handle_event/3`      | Large event router for panel switches, modals, invitation actions, and passthrough video events.    |
| `VideoLive.Index.dispatch_event/4`   | Detailed handler set for video CRUD, annotation operations, timeline controls, and modal lifecycle. |
| `RingPresence.sync_presence_topic/1` | Manages PubSub subscriptions and Presence tracking/untracking per selected ring/global view.        |
| `PanelSearch.search/2`               | Handles modal query state and ring/video search results assignment.                                 |
| `AnnotationSearch.select_result/3`   | Opens target video, sets selected annotation, and pushes seek event to player.                      |

## Client hooks (`assets/js/app.js`)

| Hook                   | Purpose                                                                                                              |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `YouTubeSeek`          | Wraps YouTube IFrame API, polls current time/duration, sends metrics to server, handles seek commands from LiveView. |
| `CopyTimestampLink`    | Builds URL with `t=...s` and copies to clipboard.                                                                    |
| `AutoGrowTextarea`     | Dynamic annotation input resizing.                                                                                   |
| `PersistDetailsOpen`   | Preserves `<details>` open/closed state in `sessionStorage`.                                                         |
| `FocusHintDisplayName` | UX helper for registration display-name guidance.                                                                    |

---

## 6) Data Model and State

## Core entities

| Entity         | Storage                      | Key fields                                       | Relationships                                                                                 |
| -------------- | ---------------------------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| User           | `users`                      | `name`, `username`, `password_hash`              | has_many videos, annotations; owns rings; memberships; invitations.                           |
| Ring           | `rings` (UUID PK)            | `name`, `invite_code`, `owner_id`                | has_many memberships/invitations/categories(via ring_id)/videos(via ring_id in videos table). |
| Membership     | `ring_memberships`           | `role`, `ring_id`, `user_id`                     | join table between users and rings.                                                           |
| RingInvitation | `ring_invitations` (UUID PK) | `status`, `ring_id`, `inviter_id`, `invitee_id`  | invitation workflow between users/rings.                                                      |
| Category       | `categories`                 | `name`, `ring_id`                                | scoped per ring; has_many videos.                                                             |
| Video          | `videos`                     | `title`, `url`, `description`, `slug`, `ring_id` | belongs_to user/category; has_many annotations.                                               |
| Annotation     | `annotations`                | `body`, `at`, `user_id`, `video_id`              | comment at timestamp for one video by one user.                                               |

## State management approach

- **Server-first state** with LiveView assigns.
- Lists that can grow (videos) use **LiveView streams** (`stream(:videos, ...)`).
- UI-only state (modal open flags, selected annotation, filters) remains in assigns.
- Presence state maintained from pubsub (`presence_subscriptions`, `online_member_ids`, `active_ring_users`).
- Client-side transient state only for hooks (player object, details expanded state).

## Data transformations worth noting

- Video slug generation from title + random suffix in `Video.changeset/2`.
- YouTube URL parsing via regex (`Video.youtube_id/1`).
- Annotation timestamp parsing supports `m:ss` and `h:mm:ss` in `Watch.parse_timestamp_to_ms/1`.
- Category migration performs SQL data repair/splitting while introducing ring scoping.

---

## 7) Dependencies and External Services

## Important libraries/frameworks

| Dependency                        | Used for                                               |
| --------------------------------- | ------------------------------------------------------ |
| Phoenix 1.8 + Phoenix LiveView    | Web framework + realtime server-rendered UI.           |
| Ecto + Ecto SQL + Postgrex        | Data modeling and PostgreSQL access.                   |
| Bcrypt (`bcrypt_elixir`)          | Password hashing/verification.                         |
| Phoenix PubSub + Phoenix Presence | Online user tracking and realtime membership activity. |
| Tailwind CSS + DaisyUI plugins    | Styling system and themed UI tokens/components.        |
| Swoosh                            | Mailer abstraction (local preview/dev setup).          |
| Bandit                            | HTTP server adapter for endpoint.                      |
| Telemetry Metrics/Poller          | Operational metrics instrumentation.                   |

## Third-party/external integrations

- **YouTube IFrame API** loaded client-side in `assets/js/app.js` for embedded playback + seek control.
- No server-side external APIs are actively called in current code paths.
- `Req` is installed but appears unused in the current repository logic.

---

## 8) Configuration and Environment

## Key config files

| File                 | Purpose                                                                        |
| -------------------- | ------------------------------------------------------------------------------ |
| `config/config.exs`  | Base app config, endpoint defaults, esbuild/tailwind build config.             |
| `config/dev.exs`     | Dev DB config, watchers, live reload patterns, debugging options.              |
| `config/test.exs`    | Test DB sandbox settings, endpoint test port, reduced logger noise.            |
| `config/prod.exs`    | Production static manifest, force SSL behavior, Swoosh API client choice.      |
| `config/runtime.exs` | Runtime env-driven settings (`DATABASE_URL`, `SECRET_KEY_BASE`, `PORT`, etc.). |

## Environment variables to know

- `DATABASE_URL` (required in prod).
- `SECRET_KEY_BASE` (required in prod).
- `PORT` (defaults to 4000).
- `POOL_SIZE` (defaults to 10).
- `PHX_SERVER` (starts endpoint in release context).
- `PHX_HOST` (public host in prod).
- `DNS_CLUSTER_QUERY` (optional clustering setup).

## Build and run scripts/aliases

- `mix setup` — deps + DB setup + asset build.
- `mix test` — creates/migrates test DB then executes tests.
- `mix assets.build` and `mix assets.deploy`.
- `mix precommit` — compile warnings-as-errors + format + tests.

---

## 9) Presentation Prep Section

## How to explain to a technical audience

“Rumbl is a Phoenix LiveView collaboration platform where users organize into ring workspaces and discuss YouTube videos with timestamped annotations. The system is built around Phoenix contexts (`Accounts`, `Rings`, `Multimedia`), with a highly interactive LiveView UI coordinated by `RingLive.Index` and `VideoLive.Index`. Presence and PubSub provide realtime online indicators, while custom JS hooks bridge LiveView with the YouTube IFrame API for timeline seeking and playback metrics.”

## How to explain to a non-technical audience

“Rumbl lets people watch and discuss videos together in private groups. Instead of leaving general comments, people can attach notes to exact moments in a video. Group owners can invite members, and everyone can see who is active in real time, making video discussions feel like a shared workspace.”

## Likely presentation questions + strong answers

| Likely question                                       | Good answer                                                                                                                                                    |
| ----------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| How is access controlled?                             | Routes are split into authenticated and non-authenticated LiveView sessions. User identity is stored in session and mounted into LiveViews via `UserLiveAuth`. |
| How do you prevent duplicate ring membership/invites? | DB uniqueness constraints + guard checks in `Rings` context enforce this.                                                                                      |
| Why LiveView instead of SPA + API?                    | Most interactions are server-driven realtime UI with minimal JS; this keeps state centralized and reduces frontend API surface area.                           |
| How does video seeking work?                          | Server emits `seek_video` events; `YouTubeSeek` hook invokes the IFrame player API.                                                                            |
| What’s most complex area?                             | `RingLive.Index` event orchestration + cross-module state coordination (presence, modals, searches, video actions).                                            |
| Is there real-time collaboration?                     | Yes: presence tracking and pubsub updates for online activity; annotation interactions are immediate via LiveView state updates.                               |

## 1-minute explanation

“Rumbl is a real-time collaborative video workspace built with Phoenix LiveView. Users join rings, upload or link YouTube videos, and leave timestamped annotations so feedback is tied to exact moments. The app combines robust backend domains for users/rings/videos with a highly interactive LiveView UI, plus presence indicators showing who’s active in each workspace. It’s designed to make video discussion structured, searchable, and collaborative.”

## 5-minute explanation

1. **Product goal:** make video collaboration structured and contextual.
2. **Core UX:** rings (group workspaces), categories, videos, annotation timeline, invite workflows.
3. **Architecture:** contexts (`Accounts`, `Rings`, `Multimedia`) + LiveView orchestration + Ecto/Postgres persistence.
4. **Realtime aspect:** Presence/PubSub for active user indicators; LiveView events for immediate UI updates.
5. **Frontend bridge:** custom hooks handle YouTube seek + rich interactions while keeping most state on server.
6. **Operational readiness:** environment-driven config, migrations, automated test support and `mix precommit`.
7. **Current caveats:** a few maintenance risks (seed script mismatch, ring_id typing, large orchestrator module).

---

## 10) Risk / Complexity Areas

## High-complexity hotspots

- `RingLive.Index` and `VideoLive.Index` each handle many events and shared state transitions; changes can cause regressions in unrelated paths.
- Presence syncing (`RingPresence`) has nuanced subscription/track/untrack logic and dual modes (selected ring vs global).

## Potential technical debt / caution points

1. **Seed script appears stale**
   - `priv/repo/seeds.exs` calls `Multimedia.get_category_by_name/1`, but context now exposes `get_category_by_name/2` and categories are ring-scoped.
   - This likely breaks current seeding path unless additional compatibility function exists (not found in `Multimedia`).
2. **`videos.ring_id` is string, while `rings.id` is UUID binary_id**
   - Several functions perform casting/validation guard rails (`list_categories_for_ring` and migration SQL regex checks), suggesting historical type migration constraints.
   - Worth highlighting as a schema consistency area.
3. **Large CSS surface (`assets/css/app.css` ~1.6k lines)**
   - Strong custom design, but maintainability may require stricter style organization conventions over time.
4. **Fallback rescue-driven flow in modal edit**
   - `VideoLive.Modal.open_edit_modal/2` uses exception rescue for not-found behavior. Works, but explicit tuple flow can be clearer and easier to test.

## Presentation caution notes

- Be ready to explain why YouTube integration is client-side hook-based (not backend API).
- Emphasize that ring scoping was added over time (migration evidence); this explains some schema evolution complexity.
- Mention that tests focus mainly on LiveView behavior/critical selectors, not exhaustive context unit coverage.

---

## 11) Glossary

| Term               | Meaning in this project                                                     |
| ------------------ | --------------------------------------------------------------------------- |
| Ring               | A collaborative workspace/group where members share videos and annotations. |
| Invite code        | Short ring code generated for join-by-code flow.                            |
| Invitation request | Pending invite record (`ring_invitations`) an invitee can accept/decline.   |
| Annotation         | Timestamped note on a video (`at` in milliseconds).                         |
| Active Now         | Presence panel showing online/offline members or global active users.       |
| LiveView           | Phoenix server-rendered realtime UI layer used by most pages.               |
| Hook               | JavaScript behavior attached to DOM nodes for specialized interactions.     |
| Stream             | LiveView mechanism for efficient rendering/updating of collections.         |
| Context            | Phoenix domain module grouping business logic + persistence operations.     |
| Ecto.Multi         | Transaction builder for multiple DB operations with rollback safety.        |

---

## 12) Executive Summary

Before presenting, the most important things to understand are:

1. Rumbl is a **ring-scoped collaborative video annotation** platform, not just a CRUD app.
2. The app’s center of gravity is the **LiveView orchestration** (`RingLive.Index` + `VideoLive.Index`) backed by clear contexts (`Accounts`, `Rings`, `Multimedia`).
3. Realtime collaboration is achieved via **LiveView events + Presence/PubSub + targeted JS hooks** for YouTube control.
4. The data model is straightforward but has **evolution complexity** around ring scoping and category/video linkage.
5. Your strongest narrative is product → architecture → realtime interactions → data model → known risks.

---

## Presentation Cheat Sheet

## Talk track bullets (quick)

- “Rumbl organizes collaboration into rings (workspaces).”
- “Users annotate videos at exact timestamps for contextual feedback.”
- “LiveView keeps most state server-side, reducing frontend complexity.”
- “Presence shows active users in real time.”
- “Ring/invitation workflows enforce group-based access control.”

## If asked “what is unique?”

- Timestamped annotation + seek integration in one collaborative workspace.
- Group-scoped access and invitation lifecycle.
- Rich realtime UX with relatively little custom JS.

## If asked “what should be improved next?”

- Split large LiveView orchestration into more explicit domain event handlers.
- Normalize schema type consistency for `ring_id` references.
- Refresh `seeds.exs` to match ring-scoped category APIs.
- Expand context-level tests for invitation/presence edge cases.

## Demo script suggestion (2–3 minutes)

1. Log in and open rings.
2. Create/join a ring.
3. Open a video in ring workspace.
4. Add annotation at timestamp.
5. Click timeline marker to seek.
6. Open invitation request flow.
7. Highlight active presence panel.
