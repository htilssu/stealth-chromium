# stealth-chromium

Patches for Chromium that add seed-keyed fingerprint variation, plus GitHub
Actions workflows that build `chrome` with them applied for Windows x64 and
Linux x64.

- `chromium_commit.txt` — the Chromium commit the patches apply to.
- `patches/` — applied in name order with `git apply`.
- `args.gn` — GN build arguments for the Windows build.
- `args-linux.gn` — GN build arguments for the Linux build.

## Building

Run the **Build** (Windows) or **Build (Linux)** workflow manually
(Actions → Build → Run workflow). Each build is split into up to 8 stages of
just under 6 hours each; the finished browser is uploaded as the
`chrome-win64` or `chrome-linux64` artifact. The two workflows keep separate
build trees, so they can run side by side.

The Linux stages run on GitHub-hosted `ubuntu-latest` runners, which have far
less disk than the Windows `D:` drive. A full Chromium tree may not fit; if a
stage's disk runs out, switch `runs-on` in `stage-linux.yml` to a
self-hosted Linux runner with ~100 GB free.

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
