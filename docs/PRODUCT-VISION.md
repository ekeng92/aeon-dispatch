# AEON Dispatch - Product Vision

> What this product is, who it's for, and why it matters.

## One-Liner

**AEON Dispatch turns GitHub Copilot into a background worker that runs tasks on a schedule and reports the results.**

## The Problem

GitHub Copilot is reactive. You open a chat, type a prompt, wait for the answer, close the chat. Every interaction requires your attention. But many development tasks are routine, predictable, and don't need you watching:

- "What did I do yesterday?" (standup prep)
- "Are there open PRs that need review?" (PR triage)
- "Is the test suite still passing?" (repo health)
- "What should I work on today?" (morning planning)
- "What did I learn today?" (end-of-day reflection)

Developers answer these questions the same way every day. The prompts don't change. The tools don't change. Only the data changes.

## The Solution

AEON Dispatch lets you save prompts as **flows**, attach them to **schedules**, and let Copilot run them automatically. Results land in markdown files you can read whenever you want. A native macOS menu bar app gives you visibility into what ran, when, and what it found.

Think of it as **cron for Copilot**.

## How It Works

```
You write a prompt  →  Save it as a flow  →  Set a schedule  →  Copilot runs it
                                                                      ↓
                              You read the result  ←  Notification lands
```

### Three primitives

| Concept | What it is | Example |
|---------|-----------|---------|
| **Customization** | An execution profile: which agent, which model, which directory | "Use Claude Sonnet in ~/Projects" |
| **Flow** | A prompt + schedule + optional customization | "Summarize my git activity, run manually" |
| **Result** | The markdown output of a completed flow | `~/.aeon-dispatch/results/git-standup/2026-05-10_1946.md` |

### Two interfaces

| Interface | For | Key actions |
|-----------|-----|-------------|
| **Menu bar app** | Glancing, triggering, configuring | See flow status, run flows, view results, manage schedules |
| **CLI (`dispatch`)** | Terminal workflows, scripting, team sharing | `dispatch run`, `dispatch list`, `dispatch sync` |

## Who It's For

### Primary: Developers who use GitHub Copilot

- Already have Copilot CLI installed (or will after seeing this)
- Comfortable with prompts and understand what Copilot can do
- Want to automate repetitive information-gathering tasks
- Use macOS as their daily driver

### Secondary: Engineering teams

- Want shared prompt libraries (via `dispatch sync` from a repo's `.dispatch/` folder)
- Need consistent standup prep, PR review cadence, or repo health checks
- Value "set it and forget it" automation

## What Makes It Useful

### 1. Zero-config start

Install with one command. Five example flows are seeded. `dispatch run git-standup` works immediately. No API keys, no config files, no accounts. If you have Copilot CLI, you have everything.

### 2. Prompts as infrastructure

Flows are JSON files. Prompts are markdown files. Both live in `~/.aeon-dispatch/` and can be version-controlled, shared, and synced across machines. `dispatch sync <folder>` imports a team's shared configurations. This makes prompts a first-class engineering artifact, not throwaway chat messages.

### 3. Results are artifacts

Every flow run produces a timestamped markdown file. These accumulate into a personal knowledge base: your standup history, your daily reflections, your repo health trends. They're grep-able, diff-able, and readable without the app.

### 4. Copilot sessions in VS Code

When a flow runs, the Copilot CLI creates a session visible in VS Code's chat history. You can open any past flow execution in the full Copilot interface, see what tools it used, and continue the conversation. The flow doesn't end when the markdown is written; it becomes a resumable session.

### 5. Native macOS experience

A 300KB menu bar app, not an Electron wrapper. Feels like a system utility. Notifications, file watchers, LaunchAgent scheduling. No browser, no web server, no Docker.

## User Journeys

### Journey 1: First-time user

1. Installs with `curl | bash`
2. Sees the menu bar icon appear
3. Clicks it, sees five flows (one enabled)
4. Runs `dispatch run git-standup` from terminal
5. Gets a rich standup report in 60-90 seconds
6. Notification pops up: "Git Standup completed (78s)"
7. Clicks the result in the app to read it in VS Code
8. Thinks: "I should run this every morning"

### Journey 2: Daily automation user

1. Enables Morning Planner (daily 8:30 AM)
2. Enables Daily Reflection (daily 4:00 PM)
3. Arrives at work, finds today's plan already written
4. Ends the day, finds a reflection capturing what shipped
5. Over weeks, builds a diary of engineering progress

### Journey 3: Team lead

1. Creates a `.dispatch/` folder in the team repo
2. Adds flows: `pr-review.json`, `repo-health.json`, custom prompts
3. Team members run `dispatch sync .` after cloning
4. Everyone gets the same automated workflows
5. PR reviews happen consistently, health checks catch regressions

### Journey 4: Power user

1. Creates custom customizations for different projects
2. Builds flows with preflight gates (only run if conditions met)
3. Writes detailed prompt files with multi-step instructions
4. Uses the CLI in CI/CD pipelines or git hooks
5. Shares flows as gists or in blog posts

## UX Principles

### The app is a dashboard, not a workspace

You don't "work" in AEON Dispatch. You glance at it. What ran? Did it work? What did it find? The real work happens in VS Code, in the terminal, or in the markdown files.

### Notifications should be actionable

When a flow completes, the notification should take you directly to the result. Not to a folder. Not to the app. To the output you care about.

### Flows should be transparent

The user should always be able to see: what prompt was sent, what agent ran it, what directory it ran in, how long it took, and what the exit code was. No black boxes.

### The CLI is the power interface

Everything the app can do, the CLI can do. The app is for visibility and quick actions. The CLI is for scripting, automation, and team workflows.

## Known Issues (Current)

| Issue | Root Cause | Fix Path |
|-------|-----------|----------|
| "Show" on notifications opens Script Editor | `osascript` notifications are attributed to Script Editor | Switch to `UNUserNotificationCenter` for native notifications (like AEON Voice) |
| Copilot sessions appear in VS Code chat | Side effect of Copilot CLI creating session records | Feature, not a bug. Document it as a benefit. Consider adding session naming |
| Result files open in default `.md` app | `NSWorkspace.shared.open()` uses system default | Could add explicit VS Code opening, or let user configure |
| No notification deep-link to result | Notifications don't carry a payload | Add `userInfo` with result file path so clicking opens the specific result |

## Future Directions

### Near-term (quality of life)

- Native notifications with deep-link to result files
- Flow execution history (last N runs per flow, not just most recent)
- Prompt preview in flow editor
- Dark/light theme parity

### Mid-term (power features)

- Flow chaining (output of one flow feeds into the next)
- Variables in prompts (`{{date}}`, `{{branch}}`, `{{repo}}`)
- Webhook triggers (run a flow when a GitHub event fires)
- Result diffing (compare today's health check to last week's)

### Long-term (platform)

- Hosted scheduling (run flows without a Mac being on)
- Flow marketplace (share and discover community flows)
- Multi-platform CLI (Linux, Windows support)
- Integration with other AI providers (not just Copilot)

## Competitive Landscape

| Product | What it does | How Dispatch differs |
|---------|-------------|---------------------|
| GitHub Actions | CI/CD automation | Dispatch is local-first, prompt-native, no YAML |
| Cron + scripts | Time-based automation | Dispatch is AI-native, results are structured, UI included |
| ChatGPT Scheduled Tasks | Scheduled prompts | Dispatch runs locally, has file access, uses your codebase context |
| Custom GPTs | Reusable prompts | Dispatch has scheduling, file system access, local execution |

## Success Metrics

For an open-source tool, success looks like:

1. **Install → first run** in under 3 minutes
2. **Weekly active flows** per user (target: 3+)
3. **GitHub stars** and forks as adoption signals
4. **"dispatch sync" usage** as team adoption signal
5. **Result file count** as engagement depth (users who accumulate 50+ results are retained)

---

*This document is the source of truth for what AEON Dispatch is building toward. Update it when the vision evolves.*
