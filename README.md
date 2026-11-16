# iphone-screen-skill

**English** · [한국어](README.ko.md)

`iphone-screen` is an agent skill for Claude Code and OpenAI Codex that captures the live screen of a USB-connected iPhone as a PNG from the macOS terminal. It lets a coding agent see what is actually on a physical device's screen while driving an app, verifying manual steps, or diagnosing why a device UI test is stuck. Only the iPhone display is captured, headlessly and without opening QuickTime.

## Requirements

- macOS with Xcode command-line tools (`swiftc`)
- An iPhone connected via USB, unlocked, and trusting the Mac
- Camera permission granted to your terminal app in **System Settings > Privacy & Security > Camera**

## Install

Clone the repository and symlink the `iphone-screen` directory into the skill directory for Claude Code, OpenAI Codex, or both.

```sh
git clone https://github.com/naelonambul/iphone-screen-skill.git
```

Claude Code (`~/.claude/skills/`):

```sh
mkdir -p ~/.claude/skills
ln -s "$(pwd)/iphone-screen-skill/iphone-screen" ~/.claude/skills/iphone-screen
```

OpenAI Codex (`~/.agents/skills/`):

```sh
mkdir -p ~/.agents/skills
ln -s "$(pwd)/iphone-screen-skill/iphone-screen" ~/.agents/skills/iphone-screen
```

## Usage

Run the wrapper script with a single output file path:

```sh
<skill-dir>/scripts/iphone-shot /tmp/phone.png
```

On success, it prints `<path> <width>x<height>` and exits `0`. Because the command only writes the PNG, the agent must then view the image file (`Read` in Claude Code, `view_image` in Codex). The first run compiles the binary into `~/.cache/iphone-screen/`; subsequent runs take about 0.6 s.

Example prompts:

- Claude Code: `Use the iphone-screen skill to capture the connected iPhone's screen and look at it.`
- OpenAI Codex: `Use $iphone-screen to capture the connected iPhone's screen and look at it.`

## Exit codes

Errors print one line to stderr and return a non-zero status.

| Exit | Message | Meaning |
| --- | --- | --- |
| 2 | `no device` | No iPhone screen appeared within 10 s (unplugged, locked, or not trusted). |
| 3 | `not authorized` | The terminal app lacks Camera permission, or a sandbox is blocking camera access. |
| 4 | `no frame` | Device found, but no video arrived within 15 s twice (the wrapper retries once automatically). Usually the phone locked or is busy. |
| 5 | `cannot write` | Output path is not writable (for example, the parent directory does not exist). |
| 64 | `usage` | Invalid arguments; pass exactly one output path. |

## Privacy

- Captures only the USB-connected iPhone screen, never the Mac screen or other windows.
- Write captures to a temporary or session scratch directory and delete them when done.
- Keep captures out of repositories and do not send them elsewhere.
- The tool never modifies system, privacy, or device settings.

## How it works

On first run, `scripts/iphone-shot` compiles `scripts/iphone-shot.swift` with `swiftc -O` and caches the binary at `~/.cache/iphone-screen/iphone-shot`. The binary sets CoreMediaIO's `kCMIOHardwarePropertyAllowScreenCaptureDevices` property so macOS exposes the USB-connected iPhone as an AVFoundation external muxed device—the same mechanism QuickTime's movie recording uses, without needing QuickTime open (and the reason `ffmpeg`'s `avfoundation` input does not list the phone, as it never sets that property). It runs an `AVCaptureSession` on the device, writes the 10th received video frame as an RGBA8 PNG via Core Image, and exits. If the first run returns exit `4` on a cold start, the shell wrapper retries once automatically.

## Limitations

- macOS only.
- Captures a single phone only (uses the first external muxed device discovered).
- Restrictive sandboxes such as Codex `workspace-write` block camera access and fail with exit `3` (`not authorized`), even when the host terminal has Camera permission; run the command outside the sandbox with normal approval.
- Intended for inspecting the live screen outside a test; XCUITest screenshots and attachments remain the oracle for test verdicts.

## License

MIT
