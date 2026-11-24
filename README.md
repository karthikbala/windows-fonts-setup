# windows-fonts-setup

One script to give a fresh Debian/Ubuntu server the font set of a real Windows
machine — for [CloakBrowser](https://github.com/CloakHQ/CloakBrowser) /
headless-browser font-fingerprint parity, PDF rendering, etc.

Installs three layers:

1. **Windows 11 / Office fonts** — real Microsoft TTFs (Calibri, Cambria, Candara,
   Consolas, Constantia, Corbel, Segoe UI, Tahoma, …) from
   [mscorefonts-extra v1.0](https://github.com/gustavomdsantos/mscorefonts-extra).
2. **Core web fonts** — Arial, Times New Roman, Courier New, Georgia, Verdana,
   Trebuchet MS, Comic Sans MS, Impact, Andale Mono, Webdings from Microsoft's
   [SourceForge cabinets](https://sourceforge.net/projects/corefonts/).
3. **Baseline emoji/CJK canvas fonts** — `fonts-noto-color-emoji`, `fonts-unifont`,
   `fonts-ipafont-gothic`, `fonts-wqy-zenhei`, … (anti-bot systems hash emoji/CJK
   canvas output; bare servers lack these).

Fonts land system-wide in `/usr/local/share/fonts/windows` (visible to every user
and service), then `fc-cache -f` runs.

## Usage

```bash
# on the server (Ubuntu/Debian, root or sudo):
curl -fsSL https://raw.githubusercontent.com/karthikbala/windows-fonts-setup/main/setup-windows-fonts.sh \
  | sudo bash -s -- --extra /path/to/msgothic.ttc
```

`--extra` is a file or directory of fonts you copied from a **licensed Windows
machine** (`C:\Windows\Fonts`). At minimum grab `msgothic.ttc` (MS UI Gothic) —
it is not redistributable, so no script can download it. Passing a whole
`C:\Windows\Fonts` copy also works and gives maximum parity (Aptos, CJK, …).

Flags:

| Flag | Default | Meaning |
|---|---|---|
| `--extra PATH` | – | file/dir of additional fonts (msgothic.ttc, full Windows Fonts dump, …) |
| `--dest DIR` | `/usr/local/share/fonts/windows` | install destination |
| `--skip-baseline` | off | skip the apt emoji/CJK canvas fonts |

The script exits non-zero and lists any missing family if CloakBrowser's
required set is incomplete: **Segoe UI, Segoe UI Light, Calibri, Marlett,
MS UI Gothic, Franklin Gothic, Consolas, Courier New**.

## Verify

```bash
fc-list | grep -iE "segoe ui|calibri|consolas|ms ui gothic"
cloakbrowser info   # reports "Win fonts: ok (8/8)" when complete
```

## Licensing notes

- Core web fonts: redistributable under the Microsoft TrueType core-fonts EULA
  (the extracted `Licen.TXT` is kept alongside the fonts).
- mscorefonts-extra: packages proprietary Windows font files; widely used but a
  licensing gray area. For production/commercial use, prefer copying fonts from
  machines you license (`--extra /path/to/Windows/Fonts`).
- `msgothic.ttc`, Aptos, and other OS/Office fonts: copy from a licensed machine.