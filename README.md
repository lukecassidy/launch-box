# my‑l(a)unch‑box

Open your daily tabs and apps on macOS with one command, powered by a small, simple config file.

Every morning, you probably open the same browser tabs and launch the same apps. This repo contains a small bash script that reads a simple config and opens everything for you.

## Install
```bash
git clone https://github.com/lukecassidy/my-launch-box.git
cd my-launch-box
chmod +x eat.sh
```

## Configuration
The default config file is `box.config` in the project root. It has two sections: `# URLs` and `# APPS`. Lines starting with `#` and blank lines are ignored.

`box.config`:
```text
# URLs
https://calendar.google.com/calendar/u/0/r/week
https://mail.google.com/mail/u/0/#inbox
https://github.com/notifications # optional inline comment

# APPS
Visual Studio Code   # editor
Slack                # chat
iTerm

# PLUGINS
iTerm                # custom script for app configuration


```

Notes:
- App names should match what you see in `/Applications` (e.g., `Visual Studio Code`, `Google Chrome`, `iTerm2`).
- The script validates apps with `open -Ra` before launching and will log a warning if an app is not found.

## Usage
Flags
- `-c, --config <file>`  Use a specific config file
- `-d, --dry-run`        Print actions without opening anything
- `-h, --help`           Show usage

Examples:
```bash
# Use the default config (box.config)
./eat.sh

# Use a custom config file
./eat.sh -c work.config
./eat.sh -c home.config

# Dry run
./eat.sh -d
```
