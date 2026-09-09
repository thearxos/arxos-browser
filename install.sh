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

# arxos-browser-mitm: opt-in Burp/mitmproxy HTTPS interception that adds ONLY the operator's
# chosen CA to their own browser stores and fully reverts. Changes no hardening pref; the
# Control Center exposes it under Hardening. cert_pinning=1 (shipped) lets it work on pinned sites.
install -Dm755 "$HERE/arxos-browser-mitm" /usr/local/bin/arxos-browser-mitm

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

# ---- one re-apply entry point ----
# A single command that re-applies every browser's hardening, for the Control Center's
# Privacy panel and for anyone who wants to re-assert it after touching browser settings
# by hand. Idempotent: it writes the same policy/pref files this installer just wrote.
install -Dm755 /dev/stdin /usr/lib/arxos/harden-browsers.sh <<'HB'
#!/bin/bash
# Re-apply ARXOS browser hardening (Firefox, Waterfox, Brave) from the installed sources.
set -u
S=/usr/share/arxos/browser
did=0
if [ -d /usr/lib/firefox ] && [ -f "$S/firefox/arxos.cfg" ]; then
  install -Dm644 "$S/firefox/policies.json" /etc/firefox/policies/policies.json 2>/dev/null
  cp -f "$S/firefox/arxos.cfg" /usr/lib/firefox/arxos.cfg
  install -Dm644 "$S/firefox/autoconfig.js" /usr/lib/firefox/defaults/pref/autoconfig.js
  echo "  Firefox hardening re-applied"; did=1
fi
if [ -d /opt/waterfox ] && [ -f "$S/waterfox/arxos.cfg" ]; then
  install -Dm644 "$S/waterfox/policies.json" /opt/waterfox/distribution/policies.json 2>/dev/null
  cp -f "$S/waterfox/arxos.cfg" /opt/waterfox/arxos.cfg
  install -Dm644 "$S/waterfox/autoconfig.js" /opt/waterfox/defaults/pref/autoconfig.js
  echo "  Waterfox hardening re-applied"; did=1
fi
if [ -f "$S/brave/arxos.json" ]; then
  install -Dm644 "$S/brave/arxos.json" /etc/brave/policies/managed/arxos.json
  echo "  Brave policy re-applied"; did=1
fi
[ "$did" = 1 ] || { echo "  no supported browser found (Firefox, Waterfox, or Brave)"; exit 1; }
echo "  Restart any open browser for the policy to take effect."
HB
# keep the installed copies of the policy sources in sync for the re-apply script
install -Dm644 "$HERE/brave/arxos.json" "$SRC/brave/arxos.json"

echo ">> ARXOS browser hardening installed: Firefox super-hardened + Brave debloated (homepage thearxos.oxborn3.com)"

# ---- ARXOS default Firefox theme: Praise the sun (animated) ----
# Drop the theme XPI into the system distribution extensions so it is active on first run
# WITHOUT touching or migrating any user profile.
install_praise_the_sun_theme() {
  # $HERE, not a bare relative path: the ISO build runs this as `bash /tmp/abr/install.sh`
  # through `chroot ... env -i ... bash -c`, which never cd's, so the CWD is / and a relative
  # "firefox/themes/..." resolved to /firefox/themes/... — it never matched, the guard below
  # silently returned, and the theme was never installed while arxos.cfg still lockPref'd
  # extensions.activeThemeID to it (Firefox locked to a missing theme). Every other path in
  # this script already uses $HERE/$S; this one was the outlier.
  local ffdir themedir xpi="$HERE/firefox/themes/praise-the-sun-animated.xpi"
  if [ ! -f "$xpi" ]; then
    # warn loudly rather than skip silently — the hardening still applies, but the locked
    # activeThemeID would point at a theme that is not there.
    echo "  !! theme XPI missing at $xpi — NOT installed (arxos.cfg locks extensions.activeThemeID to it)"
    return 0
  fi
  for ffdir in /usr/lib/firefox /usr/lib64/firefox /opt/firefox /opt/waterfox; do
    [ -d "$ffdir" ] || continue
    themedir="$ffdir/distribution/extensions"
    install -d "$themedir"
    install -m0644 "$xpi" "$themedir/{51fd00e2-c195-4740-824f-c8e789b1c066}.xpi"
    echo "  installed Praise-the-sun theme -> $themedir"
  done
}
install_praise_the_sun_theme
