---
name: iphone-screen
description: Capture the live screen of the USB-connected iPhone as a PNG from the Mac terminal, headlessly. Use when you need to see what is on the connected iPhone's screen right now, for example while driving or qualifying an app on a real device, checking what a manual step left on screen, or diagnosing why a device UI test is stuck.
---

# iPhone screen

```sh
<skill-dir>/scripts/iphone-shot <scratch-dir>/phone.png
```

`<skill-dir>` is the directory holding this file (for example `~/.claude/skills/iphone-screen` or `~/.agents/skills/iphone-screen`). On success it prints `<path> <width>x<height>` and exits 0. Then view the PNG (Claude Code: `Read`; Codex: `view_image`); the command alone shows you nothing.

The first run compiles the grabber into `~/.cache/iphone-screen/` (needs `swiftc` from Xcode); later runs take about a second.

## Rules

- Capture only the phone. Never use `screencapture` or any whole-Mac screen capture for this: it records the user's other windows.
- Write captures to a temporary or session scratch directory and delete them when you are done. The screen may show private content; do not copy captures into a repository or send them anywhere.
- Never change system, privacy or device settings yourself. If a prerequisite is missing, tell the user what to do and stop.
- This is for looking at the live screen outside a test. XCUITest screenshots and attachments remain the oracle for test verdicts.

## Prerequisites

macOS with Xcode command-line tools (`swiftc`). The phone is connected by USB, unlocked, and has trusted this Mac. The terminal app has Camera permission, granted by the user in System Settings > Privacy & Security > Camera.

## Failures

One line on stderr, non-zero exit.

| Exit | Message | Meaning |
| --- | --- | --- |
| 2 | `no device` | No iPhone screen appeared within 10 s. Phone unplugged, locked, or not trusted. |
| 3 | `not authorized` | The terminal has no Camera permission. Ask the user to grant it. |
| 4 | `no frame` | The phone was found but sent no video in 15 s, twice (a cold start is retried once automatically). Usually the phone locked or is busy; ask the user to unlock it, then run again. |
| 5 | `cannot write` | The output path is not writable, for example its directory does not exist. |
| 64 | `usage` | Pass exactly one argument, the output path. |

## Sandboxed agents

Inside a restrictive sandbox (for example Codex `workspace-write`) the camera is unavailable and the command fails with exit 3, `not authorized`, even when the terminal has permission. Run it outside the sandbox, with the agent's normal approval for such commands.
