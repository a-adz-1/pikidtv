# PiKidTV

Offline, ad-free kids' TV for Raspberry Pi: power on, local shows play, parents control it from a phone.

```
Power on → content starts → no menus → no ads → no internet dependency
```

PiKidTV turns a Raspberry Pi into a TV appliance for young children. It plays a curated library of local video files full-screen with `mpv`, starts by itself on boot, and is controlled through a mobile-friendly web page on your home network. There's no YouTube, no streaming services, no recommendations and no autoplay traps.

## Features

- **Four playback modes**
  - **Random All**: shuffles every episode in the library
  - **Single Show**: one show, optionally limited to chosen seasons, shuffled and looped
  - **Multi Show**: a quick, one-off mix of several shows
  - **Playlists**: saved mixes with per-show season choices
- **Web UI**: dark, phone-friendly control page with now playing, play/pause/skip/stop and volume. It can be added to your phone's home screen.
- **Bedtime wind-down**: at a set time it finishes the current episode, plays a night-night video, then leaves a goodnight image on screen. It runs once a day and won't re-trigger after a reboot.
- **Gentle on the hardware**: the video library is cached and refreshed every 5 minutes, and mpv is controlled over its IPC socket, so pausing or changing volume doesn't restart playback.
- **Survives power cuts**: state is saved atomically to `state.json`, and on boot it falls back to a sensible mode if the saved one can't resume.

## Hardware

- Raspberry Pi 5 (a Pi 4 should also work)
- Storage for your videos. An NVMe HAT is ideal, but a USB drive or large SD card works.
- HDMI cable to the TV
- Optional: a smart plug (for example, one running Tasmota) to switch the Pi and TV on and off together

## Install guide

These steps assume a fresh install of **Raspberry Pi OS Lite (64-bit, Bookworm or later)** with SSH enabled. The examples use a user called `pikidtv`, because the script expects its files under `/home/pikidtv`.

### 1. Flash the OS

In Raspberry Pi Imager, choose Raspberry Pi OS Lite (64-bit). Under the settings cog:

- Set the username to `pikidtv`
- Enable SSH
- Set up Wi-Fi if you're not using Ethernet

Boot the Pi and SSH in:

```bash
ssh pikidtv@<pi-ip>
```

> Tip: set up an SSH key (`ssh-copy-id pikidtv@<pi-ip>`) so you aren't locked out if you forget the password.

### 2. Fix HDMI audio and hotplug

Some TVs only send audio, or only show a picture, if the Pi forces HDMI on. Add these lines to the end of `/boot/firmware/config.txt`:

```
hdmi_drive=2
hdmi_force_hotplug=1
```

### 3. Get the code and run the installer

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/a-adz-1/pikidtv.git ~/pikidtv-src
cd ~/pikidtv-src
sudo ./install.sh
```

The installer:

- installs `mpv` and `python3-flask`
- copies `kidstv.py` to `/home/pikidtv/`
- creates `/videos` and `/home/pikidtv/bedtime`
- installs and enables the `kidstv` systemd service

It's safe to run again after pulling updates.

### 4. Add your videos

Put your shows under `/videos`, one folder per show and one subfolder per season:

```
/videos/
├── Bluey/
│   ├── Season 1/
│   │   ├── Bluey S01E01 Magic Xylophone.mkv
│   │   └── ...
│   └── Season 2/
└── Peppa Pig/
    └── Season 1/
```

- Supported formats: `.mp4`, `.mkv`, `.avi`, `.mov`
- Filenames like `Show S01E05 Title` or `Show 1x05 Title` are recognised, so the UI can show proper episode names
- New files are picked up within about 5 minutes, with no restart needed

If your videos live on a separate drive, mount it at `/videos` through `/etc/fstab`.

### 5. Add the bedtime files (optional)

```
/home/pikidtv/bedtime/night-night.mp4   # a song or short clip played after the last episode
/home/pikidtv/bedtime/goodnight.png     # stays on screen until bedtime is cleared or the Pi is switched off
```

If either file is missing, that step is skipped and the rest of bedtime still works. You can change the paths on the web UI's Settings page, which also shows whether each file is found.

### 6. Reboot

```bash
sudo reboot
```

Playback should start on the TV by itself. Open the control page from any device on your network:

```
http://<pi-ip>:5000
```

On an iPhone, tap Share and then **Add to Home Screen** to get an app-like shortcut.

## Day-to-day

| Task | Command |
|---|---|
| View recent logs | `sudo journalctl -u kidstv -n 30 --no-pager` |
| Follow logs live | `sudo journalctl -u kidstv -f` |
| Restart | `sudo systemctl restart kidstv` |
| Stop (for maintenance) | `sudo systemctl stop kidstv` |
| Update | `cd ~/pikidtv-src && git pull && sudo ./install.sh` |

## Files

| Path | What it is |
|---|---|
| `/home/pikidtv/kidstv.py` | The app: player loop and Flask web UI |
| `/home/pikidtv/state.json` | Runtime state (mode, volume, bedtime). Created automatically. |
| `/home/pikidtv/presets.json` | Saved playlists. Created automatically. |
| `/home/pikidtv/bedtime/` | Night-night video and goodnight image |
| `/videos/` | Your media library |

`state.json` and `presets.json` are personal to each install and are excluded from git.

## Troubleshooting

- **No sound:** check the `config.txt` lines in step 2, then reboot.
- **Black screen, but the web UI works:** check the logs. mpv needs access to the display, which the service gets through the `video` and `render` groups.
- **The web UI won't load:** make sure the service is running (`systemctl status kidstv`) and that you're on the same network as the Pi.
- **A show doesn't appear:** folder names under `/videos` must match exactly, and files must use a supported extension. Wait 5 minutes for the cache to refresh, or restart the service.
- **The smart plug dropped off Wi-Fi:** Tasmota plugs can be reset with a long press of the button, which brings back their setup access point.

## Design principles

- Offline first
- No algorithms and no autoplay traps
- Simple for kids, controlled by parents
- Behaves like an appliance

## Licence

Copyright (C) 2026 a-adz-1

PiKidTV is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See [LICENSE](LICENSE).
