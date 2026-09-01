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

# ---- Waterfox (waterfox-bin: installs to /opt/waterfox; same Mozilla toolkit, same
# policies.json + autoconfig.js mechanism as Firefox, so it gets the same hardening) ----
install -Dm644 "$HERE/waterfox/arxos.cfg"     "$SRC/waterfox/arxos.cfg"
install -Dm644 "$HERE/waterfox/autoconfig.js" "$SRC/waterfox/autoconfig.js"
if [ -d /opt/waterfox ]; then
  install -Dm644 "$HERE/waterfox/policies.json" /opt/waterfox/distribution/policies.json
  cp -f "$SRC/waterfox/arxos.cfg" /opt/waterfox/arxos.cfg
  install -Dm644 "$SRC/waterfox/autoconfig.js" /opt/waterfox/defaults/pref/autoconfig.js
fi
install -Dm755 /dev/stdin /usr/lib/arxos/reapply-waterfox.sh <<'RS'
#!/bin/bash
[ -d /opt/waterfox ] || exit 0
install -Dm644 /usr/share/arxos/browser/waterfox/policies.json /opt/waterfox/distribution/policies.json
cp -f /usr/share/arxos/browser/waterfox/arxos.cfg /opt/waterfox/arxos.cfg
install -Dm644 /usr/share/arxos/browser/waterfox/autoconfig.js /opt/waterfox/defaults/pref/autoconfig.js
RS
install -Dm644 /dev/stdin /usr/share/libalpm/hooks/arxos-waterfox-harden.hook <<'HK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = waterfox-bin
Target = waterfox
[Action]
Description = Reapplying ARXOS Waterfox hardening...
When = PostTransaction
Exec = /usr/lib/arxos/reapply-waterfox.sh
HK

# ---- Brave ----
install -Dm644 "$HERE/brave/arxos.json" /etc/brave/policies/managed/arxos.json
install -Dm644 "$HERE/brave/brave-flags.conf" /etc/skel/.config/brave-flags.conf
if [ -d /home/arxos/.config ]; then
  install -Dm644 "$HERE/brave/brave-flags.conf" /home/arxos/.config/brave-flags.conf
  chown arxos:arxos /home/arxos/.config/brave-flags.conf
fi

echo ">> ARXOS browser hardening installed: Firefox super-hardened + Brave debloated (homepage thearxos.oxborn3.com)"

# ---- ARXOS default Firefox theme: Praise the sun (animated) ----
# Drop the theme XPI into the system distribution extensions so it is active on first run
# WITHOUT touching or migrating any user profile.
install_praise_the_sun_theme() {
  local ffdir themedir xpi="firefox/themes/praise-the-sun-animated.xpi"
  [ -f "$xpi" ] || return 0
  for ffdir in /usr/lib/firefox /usr/lib64/firefox /opt/firefox /opt/waterfox; do
    [ -d "$ffdir" ] || continue
    themedir="$ffdir/distribution/extensions"
    install -d "$themedir"
    install -m0644 "$xpi" "$themedir/{51fd00e2-c195-4740-824f-c8e789b1c066}.xpi"
    echo "  installed Praise-the-sun theme -> $themedir"
  done
}
install_praise_the_sun_theme
