#!/usr/bin/env bash
# Install real Windows fonts + baseline emoji/CJK canvas fonts on a Debian/Ubuntu
# server, for CloakBrowser / headless-browser font parity with a real Windows box.
#
# Sources:
#   - mscorefonts-extra v1.0 (Windows 11 font files: Calibri, Cambria, Segoe UI, ...)
#   - Microsoft "Core fonts for the Web" cabinets from SourceForge (Arial, Times, ...)
#   - optional --extra file/dir for non-redistributable fonts you copy from a
#     licensed Windows machine (e.g. msgothic.ttc, Aptos, or a whole C:\Windows\Fonts)
#
# Usage: sudo bash setup-windows-fonts.sh [--extra PATH] [--dest DIR] [--skip-baseline]
set -euo pipefail

DEST=/usr/local/share/fonts/windows
EXTRA=""
SKIP_BASELINE=0

usage() { sed -n '2,12p' "$0"; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --extra) EXTRA=$2; shift 2 ;;
    --dest) DEST=$2; shift 2 ;;
    --skip-baseline) SKIP_BASELINE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
done

SUDO=""
[[ $(id -u) -ne 0 ]] && SUDO=sudo
export DEBIAN_FRONTEND=noninteractive

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/fonts"

echo "==> prerequisites (curl, cabextract, binutils, zstd, fontconfig)"
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq \
  curl ca-certificates cabextract binutils zstd fontconfig tar

echo "==> mscorefonts-extra v1.0 (Office + Windows 11 fonts)"
curl -fsSL -o "$WORK/extra.deb" \
  https://github.com/gustavomdsantos/mscorefonts-extra/releases/download/v1.0/mscorefonts-extra_1.0_all.deb
(cd "$WORK" && ar x extra.deb)
tar -xf "$WORK"/data.tar.* -C "$WORK"
nested=$(find "$WORK/usr" -type f -name '*.tar.*' -print -quit)
[[ -n "$nested" ]] || { echo "ERROR: nested font tarball not found in deb" >&2; exit 1; }
tar -xf "$nested" -C "$WORK/fonts"
find "$WORK/fonts" -mindepth 2 -type f -exec mv -t "$WORK/fonts" {} +
find "$WORK/fonts" -mindepth 1 -type d -empty -delete

echo "==> core web fonts (SourceForge, Microsoft EULA)"
for f in andale32 arial32 arialb32 comic32 courie32 georgi32 impact32 \
         times32 trebuc32 verdan32 webdin32; do
  curl -fsSL -o "$WORK/$f.exe" \
    "https://downloads.sourceforge.net/project/corefonts/the%20fonts/final/$f.exe"
done
cabextract -q -d "$WORK/fonts" "$WORK"/*.exe
# drop Windows-installer leftovers, keep the EULA text (Licen.TXT)
rm -f "$WORK/fonts/ADVPACK.DLL" "$WORK/fonts/W95INF16.DLL" "$WORK/fonts/W95INF32.DLL" \
      "$WORK/fonts/fontinst.exe" "$WORK/fonts/fontinst.inf" "$WORK/fonts/andale.inf"

if [[ -n "$EXTRA" ]]; then
  echo "==> extra fonts from $EXTRA"
  if [[ -d "$EXTRA" ]]; then
    find "$EXTRA" -type f \( -iname '*.ttf' -o -iname '*.ttc' -o -iname '*.otf' \) \
      -exec cp -f {} "$WORK/fonts/" \;
  elif [[ -f "$EXTRA" ]]; then
    cp -f "$EXTRA" "$WORK/fonts/"
  else
    echo "ERROR: --extra path not found: $EXTRA" >&2; exit 1
  fi
fi

echo "==> installing to $DEST"
$SUDO mkdir -p "$DEST"
$SUDO cp -a "$WORK/fonts/." "$DEST/"
$SUDO fc-cache -f

if [[ $SKIP_BASELINE -eq 0 ]]; then
  echo "==> baseline emoji/CJK canvas fonts (anti-bot canvas parity)"
  $SUDO apt-get install -y -qq \
    fonts-noto-color-emoji fonts-freefont-ttf fonts-unifont \
    fonts-ipafont-gothic fonts-wqy-zenhei fonts-tlwg-loma-otf
fi

echo "==> verifying CloakBrowser's required Windows families"
# capture once: `fc-list | grep -q` would SIGPIPE fc-list and, under pipefail,
# make every present family look missing
FONT_LIST=$(fc-list)
missing=0
for fam in "Segoe UI" "Segoe UI Light" "Calibri" "Marlett" "MS UI Gothic" \
           "Franklin Gothic" "Consolas" "Courier New"; do
  if grep -qi "$fam" <<< "$FONT_LIST"; then
    echo "  ok      $fam"
  else
    echo "  MISSING $fam"
    missing=1
  fi
done

if [[ $missing -ne 0 ]]; then
  echo
  echo "MS UI Gothic (msgothic.ttc) and other non-redistributable fonts must come"
  echo "from a licensed Windows machine (C:\\Windows\\Fonts). Copy them over and rerun:"
  echo "  sudo bash $0 --extra /path/to/msgothic.ttc"
  exit 1
fi

echo "==> done: $(find "$DEST" -type f | wc -l) files in $DEST"