#!/usr/bin/env bash
# PiKidTV installer. Safe to re-run after a `git pull`.
set -euo pipefail

APP_USER="pikidtv"
APP_HOME="/home/${APP_USER}"
VIDEO_ROOT="/videos"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo: sudo ./install.sh" >&2
  exit 1
fi

if ! id "${APP_USER}" &>/dev/null; then
  echo "User '${APP_USER}' does not exist. Create it first, or flash the OS with that username." >&2
  exit 1
fi

if [[ ! -f "${SRC_DIR}/kidstv.py" ]]; then
  echo "kidstv.py not found next to install.sh" >&2
  exit 1
fi

echo "==> Installing packages"
apt-get update
apt-get install -y mpv python3-flask

echo "==> Adding ${APP_USER} to the video, render and audio groups"
usermod -aG video,render,audio "${APP_USER}"

echo "==> Creating folders"
install -d -o "${APP_USER}" -g "${APP_USER}" "${APP_HOME}/bedtime"
install -d -o "${APP_USER}" -g "${APP_USER}" "${VIDEO_ROOT}"

echo "==> Installing kidstv.py"
install -m 755 -o "${APP_USER}" -g "${APP_USER}" "${SRC_DIR}/kidstv.py" "${APP_HOME}/kidstv.py"

echo "==> Installing systemd service"
install -m 644 "${SRC_DIR}/kidstv.service" /etc/systemd/system/kidstv.service
systemctl daemon-reload
systemctl enable kidstv
systemctl restart kidstv

IP="$(hostname -I | awk '{print $1}')"
echo
echo "Done. PiKidTV is running."
echo "  Web UI:  http://${IP}:5000"
echo "  Logs:    sudo journalctl -u kidstv -n 30 --no-pager"
echo "  Videos:  ${VIDEO_ROOT}/Show Name/Season N/episode.mkv"
echo "  Bedtime: ${APP_HOME}/bedtime/night-night.mp4 and goodnight.png"
