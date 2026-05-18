# Project Learning Notes

These notes explain the work so far in beginner-friendly language. They are not a raw changelog. The goal is to help you understand why the project was shaped this way and what each part is supposed to do.

## Already Implemented

This section describes project pieces that have already been created or drafted in the repository.

### 1. Project Setup

We created a React + Vite app because it is a simple, modern way to build a frontend.

React lets us build the interface as small reusable pieces called components. Vite gives us a fast development server, quick refresh while editing, and a clean build setup without needing a lot of custom configuration.

`package.json` is the project manifest. It lists the app's dependencies, scripts, and basic project metadata. When a command like `npm install` runs, the package manager reads this file to know what libraries the project needs. When a command like `npm run dev` runs, it also comes from the scripts defined there.

`index.html` is the browser entry page. In a Vite React app, it usually contains a single root element where React mounts the app. The browser loads this HTML file first, then Vite loads the JavaScript that starts React.

`src/main.jsx` is the JavaScript entry point. Its job is to connect React to the HTML page. It finds the root element from `index.html` and tells React to render the app there.

`src/App.jsx` is the main app component. It controls the top-level structure of the frontend, such as which shell, pages, or layout are shown.

We are using plain CSS for now because the project is still early. Plain CSS keeps the styling easy to inspect and easy to learn. It avoids adding a design framework before the app's real screens and patterns are clear.

The app shell, pages, and components each have a different purpose:

- The app shell is the shared frame around the app, such as navigation, layout, and common page structure.
- Pages represent larger screens or routes, such as dashboard-style views.
- Components are smaller reusable UI pieces used inside pages, such as panels, buttons, forms, lists, or status sections.

### 2. Documentation Structure

`README.md` exists as the main human-facing starting point for the project. It should explain what the project is, how to run it, and the most important things a developer should know first.

The `docs/` folder exists for deeper human documentation. It can hold learning notes, architecture explanations, setup guides, security notes, and other material that would make the README too long.

The `ai_agents/` folder exists for AI handoff context. These files help an AI assistant understand current project state, decisions, constraints, and known risks across sessions.

Human docs and AI handoff docs are related, but they are not the same:

- Human docs should teach, explain, and onboard a real person.
- AI handoff docs should preserve operational context so future AI work does not accidentally repeat mistakes or ignore important constraints.

Keeping project state, decisions, and security notes matters because software projects are not just code. They also contain reasoning. Recording why a decision was made helps prevent future changes from breaking security, privacy, or the intended product behavior.

### 3. Supabase Planning

Supabase is planned to handle the backend side of the app.

It will provide authentication, so users can sign in and the app can know who they are.

It will provide the database, where project data such as profiles, guilds, memberships, CP values, GvG events, votes, and audit logs can live.

It will provide Row Level Security, usually called RLS. RLS lets the database decide which rows a user is allowed to read, insert, update, or delete.

It will also provide RPC functions. In Supabase, RPC functions are database functions that the frontend can call. They are useful when a sensitive action should happen through controlled backend logic instead of direct table access.

We planned before coding real backend logic because the data model is security-sensitive. CP privacy, role permissions, audit logs, and voting rules all need careful database rules. Planning first reduces the chance of building frontend screens that assume unsafe backend behavior.

### 4. Database Design

The planned database is organized around guild management, member identity, CP tracking, GvG voting, permissions, and auditing.

`profiles` represents app users. A profile stores basic identity information connected to an authenticated user, but it should not store private CP values.

`guilds` represents guilds managed by the app. A guild is the main group or organization that members belong to.

`guild_memberships` connects profiles to guilds. This table answers questions like "which guild is this user in?" and "what role does this user have in that guild?"

`member_cp` stores current CP data. CP is sensitive, so this table should be protected carefully and should not be readable by ordinary members directly.

`cp_snapshots` stores historical CP records. Snapshots are useful for tracking changes over time, reviewing growth, and preserving previous CP states.

`gvg_events` stores Guild versus Guild events. These are the events members may vote for or respond to.

`gvg_votes` stores member votes for GvG events. It records each user's response for a specific event, such as whether they can attend or why they may be absent.

`audit_logs` stores important security and administrative actions. Audit logs help answer "who did what, and when?" They are especially important for sensitive actions such as CP permission changes or membership approvals.

Permission tables store role capabilities and admin permission grants. They let the project avoid hard-coding every permission directly into app screens.

### 5. CP Privacy

CP is not stored in `profiles` because profiles are general identity records. CP is more sensitive than basic identity, so keeping it in separate protected tables makes privacy rules easier to enforce.

Members must not directly read CP tables because direct table access could expose private member data. Even if the frontend does not show CP, a user might still call the backend directly if the database allows it.

Frontend hiding is not security. Hiding a button, field, or page only changes what the browser displays. Real security must happen on the backend and in the database.

RLS and RPC protections matter because they enforce rules close to the data. RLS limits row access, and RPC functions can wrap sensitive actions in controlled logic.

### 6. Roles and Permissions

The project uses several planned roles:

- Owner is the highest-trust role. The Owner controls the most sensitive permissions, especially CP-related permission grants.
- Leader is a high-level guild role with broad management responsibility.
- Vice is a leadership role with important but more limited authority than Owner or Leader.
- Admin is a flexible role whose exact permissions can be granted with checkboxes.
- Member is a regular guild member with limited access.

Admin permissions use checkboxes because not every admin should automatically have every power. One admin might help with GvG events, while another might help with approvals or member management.

Owner controls sensitive CP permission grants because CP data is private. Permission to view or manage CP should be explicit and tightly controlled.

### 7. GvG Voting

One vote per user per event matters because voting should represent each member's latest answer, not a pile of repeated answers.

A unique constraint on `(event_id, profile_id)` matters because it lets the database enforce this rule. Even if the frontend has a bug, the database can still prevent duplicate votes for the same user and event.

Switching a vote should update the existing vote instead of inserting a new row. That keeps the vote table clean and makes each user's current choice easy to find.

An absence reason is admin-visible because leaders may need to understand why someone cannot attend. It should not be treated as general public data for all members.

### 8. SQL Migrations

Migrations are versioned database change files. They describe how the database schema changes over time.

Migration order matters because later migrations may depend on tables, functions, or policies created earlier. For example, a policy for `gvg_votes` cannot exist before the `gvg_votes` table exists.

Timestamped migration files are used so the database can apply changes in a predictable order. The timestamp at the start of a migration filename acts like a timeline.

The migration files are responsible for different pieces of the backend plan:

- Initial schema migrations create the core tables such as profiles, guilds, memberships, CP tables, GvG tables, audit logs, and permission tables.
- Constraint migrations add rules such as uniqueness, required fields, or relationships between tables.
- RLS migrations enable row-level security and define who can read or write each table.
- RPC/function migrations create controlled database functions for sensitive reads and writes.
- Security hardening migrations fix risky access patterns, adjust grants, and close direct table operations that should go through functions.

The owner bootstrap template is outside migrations because it is environment-specific. A migration should be safe and repeatable for every environment, while bootstrapping the first Owner may require project-specific user IDs or setup steps.

### 9. RLS and RPC Basics

RLS means Row Level Security. In simple words, it lets the database ask: "Is this user allowed to access this row?"

Without RLS, a table permission may accidentally apply too broadly. With RLS, access can depend on the current user, guild membership, role, or permission grants.

RPC functions are database functions that the app can call. They are useful for actions like approving a member, updating a vote, reading protected CP data, or writing audit logs in a controlled way.

Sensitive write and read operations go through functions because functions can check permissions, perform multiple steps safely, and prevent users from directly changing protected tables.

`SECURITY DEFINER` means a function can run with the privileges of the function owner instead of the caller. At a high level, this lets a normal user request a controlled action without giving that user direct table access.

`search_path` matters because database functions need to resolve table and function names safely. Setting it deliberately helps avoid unexpected name resolution.

Grants matter because they decide who can call a function or access a table. A well-written function is still risky if too many users can call it or if private helper functions are exposed.

### 10. Docker and Supabase Local Validation

Docker runs services in isolated containers. For local Supabase, Docker provides the local database and related Supabase services without needing to install and configure each service manually.

Supabase local needs Docker because the local development stack includes several backend services. Docker makes those services reproducible.

The Supabase CLI is the command-line tool used to manage local Supabase development.

`supabase start` starts the local Supabase services.

`supabase db reset` rebuilds the local database from migrations. This is useful for checking whether migrations apply cleanly from scratch. In local validation, the migrations applied successfully with `npx.cmd supabase db reset`.

`supabase stop` stops the local Supabase services.

Local validation is safer than production because mistakes happen in a disposable local environment first. A broken migration or bad policy should be caught locally before it can affect real users or real data.

### 11. Security Reviews We Performed

Several security review themes were identified and addressed in the planned backend design.

The private function grants issue was about making sure helper functions are not callable by regular users unless they are meant to be public API functions. Private helpers should stay private.

The audit log spoofing risk was about preventing users from writing fake audit entries. Audit logs should be created by trusted functions so users cannot pretend someone else performed an action.

The direct GvG vote update risk was about preventing users from bypassing controlled voting logic. Vote changes should follow the intended one-vote-per-user-per-event behavior.

The approval flow safety issue was about making sure membership approval cannot be abused. Approval should check that the acting user has the right role or permission.

The reapply and rejection cleanup issue was about keeping membership request state clean. If a user reapplies or is rejected, old state should not create confusing or unsafe membership behavior.

These were fixed by tightening grants, moving sensitive actions into RPC functions, relying on database constraints, and using RLS policies instead of trusting frontend-only checks.

Local validation later found an important real bug in private helper functions. Some helper parameters had names similar to table columns, which could make permission checks too broad. That created CP/RPC permission leakage during testing. The helper parameters were renamed with `p_*` prefixes, such as `p_profile_id` and `p_guild_id`, so comparisons clearly mean "table column equals function parameter." After that fix, local validation passed with 29 PASS, 0 FAIL, and 0 SKIP.

## Implemented Since These Notes

This section was originally written early in the project. The core local Supabase-backed flows below have since been implemented and validated through Milestone 11B.

### Supabase Auth Integration

The frontend now uses Supabase auth/session state, registration through `register_profile`, and pending/rejected/suspended/approved gates.

### Backend Data Flow

Sensitive reads and writes now flow through RLS-safe table reads and permission-checked RPCs. Production deployment is still pending.

### CP Management

Admin-only CP management and leaderboard flows are implemented and browser validated. Members still must never see CP values.

### Permission Enforcement

Role and permission enforcement is implemented through database-side checks and RPCs. Permission checkbox management uses grant/revoke RPCs.

### GvG Voting

GvG event management and voting are implemented and live-browser validated. The one-vote-per-event/profile rule is enforced by the database and voting RPC.

## Needs Validation

This section lists the work that should be checked before continuing into deeper implementation.

### 12. Current Project Status

Implemented:

- A React + Vite frontend foundation.
- Basic project structure for app code, pages, components, and styling.
- Documentation areas for human docs and AI handoff docs.
- Supabase planning for auth, database structure, RLS, RPC functions, permissions, CP privacy, GvG voting, and audit logs.
- Security review notes and planned fixes for sensitive backend behavior.
- Local Supabase auth/register/pending flow.
- Approval/rejection, profile editing, member management, role/guild management, permission checkbox management, CP management, GvG voting, and audit log viewer.

Still not implemented:

- Production deployment or production Supabase changes.
- Reapply UI.
- Suspended/left/rejected member management.
- Weekly CP snapshot/growth report UI.
- Guild/subguild management UI.

Validated locally:

- Migrations applied locally from a clean database.
- RLS policies were tested with different user roles.
- RPC functions were tested for allowed and denied users.
- Audit logging was tested to confirm users cannot spoof logs.
- GvG vote updates were tested to confirm duplicate votes are not inserted.
- CP privacy was tested to confirm ordinary members cannot read protected CP data directly or through CP RPCs.

### 13. Next Learning Steps

The local Supabase validation step has now passed. The next learning step is planning frontend integration with Supabase Auth and the validated RPC functions.

Only after local database behavior is trusted should real auth integration be connected in the frontend. This order keeps the project safer because the backend rules are proven before the UI depends on them. The backend rules are now locally validated, but they are not yet deployed to production or connected to the frontend.

## Important Warnings

Frontend hiding is not security. A hidden button does not protect private data.

CP data must stay separate from general profile data and must be protected by database rules.

Members should not directly read CP tables.

Sensitive actions should go through controlled RPC functions, not unrestricted direct table edits.

Migration files should not be edited casually after they are relied on. If the database has already used a migration, a new migration is usually safer than rewriting history.

Local validation should happen before production changes.

The owner bootstrap process should stay outside normal migrations because it depends on environment-specific setup.
