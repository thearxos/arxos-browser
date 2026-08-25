#!/usr/bin/env bash
# arxos-browser - ARXOS hardened + debloated Firefox & Brave defaults (global, every user).
# Firefox: enterprise policies + a deep autoconfig, with a pacman hook so it survives updates
# (Firefox replaces its lib dir on upgrade). Brave: global managed policy killing Leo AI, Rewards,
# Wallet, VPN, telemetry + extra launch flags. Homepage = thearxos.oxborn3.com, search = DuckDuckGo.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=/usr/share/arxos/browser

# ---- ARXOS welcome page (local homepage for Firefox + Brave) ----
install -Dm644 "$HERE/welcome.html" "$SRC/welcome.html"

# ---- Firefox ----
install -Dm644 "$HERE/firefox/arxos.cfg"     "$SRC/firefox/arxos.cfg"       # persistent source
install -Dm644 "$HERE/firefox/autoconfig.js" "$SRC/firefox/autoconfig.js"
install -Dm644 "$HERE/firefox/policies.json" /etc/firefox/policies/policies.json
cp -f "$SRC/firefox/arxos.cfg" /usr/lib/firefox/arxos.cfg
install -Dm644 "$SRC/firefox/autoconfig.js" /usr/lib/firefox/defaults/pref/autoconfig.js
# survive firefox upgrades: reapply the autoconfig after the package replaces /usr/lib/firefox
install -Dm755 /dev/stdin /usr/lib/arxos/reapply-firefox.sh <<'RS'
#!/bin/bash
cp -f /usr/share/arxos/browser/firefox/arxos.cfg /usr/lib/firefox/arxos.cfg
install -Dm644 /usr/share/arxos/browser/firefox/autoconfig.js /usr/lib/firefox/defaults/pref/autoconfig.js
RS
install -Dm644 /dev/stdin /usr/share/libalpm/hooks/arxos-firefox-harden.hook <<'HK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = firefox
[Action]
Description = Reapplying ARXOS Firefox hardening...
When = PostTransaction
Exec = /usr/lib/arxos/reapply-firefox.sh
HK

# ---- Brave ----
install -Dm644 "$HERE/brave/arxos.json" /etc/brave/policies/managed/arxos.json
install -Dm644 "$HERE/brave/brave-flags.conf" /etc/skel/.config/brave-flags.conf
if [ -d /home/arxos/.config ]; then
  install -Dm644 "$HERE/brave/brave-flags.conf" /home/arxos/.config/brave-flags.conf
  chown arxos:arxos /home/arxos/.config/brave-flags.conf
fi

echo ">> ARXOS browser hardening installed: Firefox super-hardened + Brave debloated (homepage thearxos.oxborn3.com)"
