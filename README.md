# stealth-chromium

Patches for Chromium that add seed-keyed fingerprint variation, plus a GitHub
Actions workflow that builds a Windows x64 `chrome` with them applied.

- `chromium_commit.txt` — the Chromium commit the patches apply to.
- `patches/` — applied in name order with `git apply`.
- `args.gn` — GN build arguments.

## Building

Run the **Build** workflow manually (Actions → Build → Run workflow). The build
is split into up to 8 stages of just under 6 hours each; the finished browser
is uploaded as the `chrome-win64` artifact.

## Usage

Nothing changes unless `--fingerprint=<seed>` is passed. The same seed always
produces the same fingerprint.

```
chrome.exe --fingerprint=12345 ^
  --fingerprint-hardware-concurrency=8 ^
  --fingerprint-device-memory=8 ^
  --fingerprint-platform=Win32 ^
  --fingerprint-gpu-vendor="Google Inc. (NVIDIA)" ^
  --fingerprint-gpu-renderer="ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0, D3D11)"
```
