# my‑l(a)unch‑box

Open your daily tabs and apps on macOS with one command, powered by a small, simple config file.

Every morning, you probably open the same browser tabs, launch the same apps, configure them and arrange windows in the same layout. This repo reads a simple config and does it all for you.

## Install
```bash
git clone https://github.com/lukecassidy/my-launch-box.git
cd my-launch-box
chmod +x eat.sh
```

## Configuration
The default config file is `box.config` in the project root. It has three sections: `# URLs`, `# APPS` and `# PLUGINS`. Lines starting with `#` and blank lines are ignored. Inline comments (after a space + `#`) are supported.

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
iTerm       # Run plugin script to configure iTerm (split panes, run commands etc)
layout      # Run plugin script to arrange windows/screens

```

Sections:
- **URLs**: Any valid `http`/`https` links. They will open in your default browser.
- **APPS**: Application names should match what you see in `/Applications` (e.g., `Visual Studio Code`, `Google Chrome`, `Slack`).
- **PLUGINS**: Each entry corresponds to a script in `plugins`. Plugins allow you to configure apps after launch (e.g., apply defaults, tweak settings) or set up your workspace (e.g., arrange window layout, position screens).

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

Alright, here’s a more casual rewrite of that section, keeping it simple and friendly:


---

## Run When You Need It

There are lots of different ways to run it from here. You can fire off eat.sh straight from the terminal. You could configure the script to run on startup. Another approach is to pop a button in the macOS menu bar and run it when you need it. I like this approach so I'll outline it here. 

### Add a Menu Bar Button (using Shortcuts)
1. Open the Shortcuts app.
2. Make a new shortcut → add Run Shell Script.
3. Drop in the full path to your script, e.g.:
/Users/you/my-launch-box/eat.sh
4. In the shortcut settings, turn on 'Pin in Menu Bar'.

That’s it. Now you've got button in your menu bar that kicks everything off with one click 🌯.

---

## TODO
- [ ] Add gif of usage to README.md.
- [ ] Expand iTerm config.
- [ ] Support multiple Chrome profiles.
- [ ] Make plugins more user friendly (currently hardcoded to my setup).
- [ ] Expand layout script to handle different monitor setups.

**Note**: This project is a work in progress. Just a bit of fun I started after realising I manually open the same tabs and apps every day, then spend about 5 minutes rearranging windows.

