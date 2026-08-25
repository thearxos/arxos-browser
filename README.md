# arxos-browser

ARXOS's hardened, debloated browser defaults — applied globally so every account created at install
inherits them. Homepage `thearxos.oxborn3.com`, search **DuckDuckGo**.

## Firefox — super-hardened
- **Telemetry / studies / crash-reporting**: off and locked.
- **Anti-fingerprinting**: `resistFingerprinting` + `fingerprintingProtection` (RFP forces a light
  theme + UTC clock — the cost of maximum unlinkability).
- **Tracking**: strict ETP (trackers, cryptominers, fingerprinters, social, email).
- **Cookies**: total cookie protection (cross-site trackers blocked, rest partitioned).
- **WebRTC**: on, but never leaks the local/private IP.
- **Prefetch / speculative connections**: all off (no phantom requests).
- **HTTPS-only**, DoH via Quad9, referer trimmed cross-origin, geo/sensors/autofill/password-save off.
- **uBlock Origin** auto-installed; Pocket, sponsored tiles, snippets, onboarding all removed.
- Delivered via enterprise `policies.json` + an autoconfig (`arxos.cfg`), with a **pacman hook** that
  reapplies after every Firefox update.

## Brave — hardened + debloated
Managed policy kills **Leo AI, Rewards, Wallet, VPN, Talk**, all telemetry/metrics, background
networking, promo tabs, NTP cards/sponsored images, password/autofill; keeps **Tor + Shields**.
HTTPS-only, DoH/Quad9, WebRTC IP-leak protection, DuckDuckGo. Extra launch flags in `brave-flags.conf`.

## Install
```
sudo ./install.sh
```
