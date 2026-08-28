#!/usr/bin/env bash
#
# timelapse.sh — point it at a project folder, get one video.
#
#   ./timelapse.sh ~/Pictures/myproject
#
# It scans the whole folder tree, finds every photo at any depth, and puts them
# in order. Your layout works as-is:
#
#   myproject/
#     20250813/timelapse_06-30-00-000.jpg
#     20250813/timelapse_06-30-30-000.jpg
#     20250814/timelapse_06-30-00-000.jpg
#
# Ordering is just a sort of the full path. YYYYMMDD folders sort oldest-first
# and timelapse_HH-MM-SS-mmm files sort earliest-first, so the sort alone puts
# every frame in the right place — no matter how the folders are nested.
#
# Originals are never renamed, moved or modified.
#
# Requires ffmpeg:  brew install ffmpeg
#
# No `set -u`: macOS ships bash 3.2, which errors on empty array expansion.
set -eo pipefail

FPS=30
CRF=18
SCALE=""
OUT=""
DEFLICKER=0
DRYRUN=0
REVERSE=0

usage() {
  cat <<'EOF'
Usage: timelapse.sh [options] <project folder>

Scans the folder (and everything under it) for photos and builds one video.

Options:
  -r FPS     frame rate (default 30). Lower = longer video.
  -s WIDTH   scale to WIDTH px wide, height auto (e.g. -s 1920 or -s 3840).
             Omit to keep the source resolution.
  -o FILE    output file (default: <project folder>/<name>.mp4)
  -q CRF     quality, 0-51, lower is better (default 18; 23 = smaller file)
  -d         deflicker (helps if auto-exposure made the frames pulse)
  -x         reverse the sequence
  -n         dry run: show what it found, don't encode
  -h         this help
EOF
}

while getopts "r:s:o:q:dxnh" opt; do
  case "$opt" in
    r) FPS="$OPTARG" ;;
    s) SCALE="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    q) CRF="$OPTARG" ;;
    d) DEFLICKER=1 ;;
    x) REVERSE=1 ;;
    n) DRYRUN=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

DIR="${1:-.}"
[ -d "$DIR" ] || { echo "error: no such folder: $DIR" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "error: ffmpeg not found. Run: brew install ffmpeg" >&2; exit 1; }
DIR="$(cd "$DIR" && pwd)"
[ -n "$OUT" ] || OUT="$DIR/$(basename "$DIR").mp4"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LIST="$TMP/frames.txt"

# ---- find every photo, at any depth, in order -----------------------------
# -not -name '.*' skips macOS AppleDouble stubs (._timelapse_00-00-01-000.jpg),
# which appear all over SD-card copies, match an image glob, and are not images.
find "$DIR" -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
     -o -iname '*.tif' -o -iname '*.tiff' \) \
  -not -name '.*' -print 2>/dev/null | LC_ALL=C sort > "$LIST"

COUNT=$(wc -l < "$LIST" | tr -d ' ')

# ---- if that found nothing, say exactly what IS there ---------------------
if [ "$COUNT" -lt 2 ]; then
  echo "error: found $COUNT usable photo(s) under $DIR" >&2
  echo >&2
  echo "What's actually in there:" >&2
  SUBS=$(find "$DIR" -mindepth 1 -maxdepth 2 -type d -not -name '.*' 2>/dev/null | LC_ALL=C sort)
  if [ -n "$SUBS" ]; then
    echo "$SUBS" | head -15 | while IFS= read -r d; do
      n=$(find "$d" -maxdepth 1 -type f -not -name '.*' 2>/dev/null | wc -l | tr -d ' ')
      printf '  %-40s %s file(s)\n' "${d#$DIR/}/" "$n" >&2
    done
  else
    echo "  (no subfolders)" >&2
  fi
  echo >&2
  echo "File types present:" >&2
  # awk, not sed: a plain "s/^[^.]*$/(no extension)/" fallback fires on the
  # already-stripped extension too, and mislabels every file.
  TYPES=$(find "$DIR" -type f -not -name '.*' 2>/dev/null | awk -F/ '
    { f = $NF
      if (match(f, /\.[^.]+$/)) print tolower(substr(f, RSTART + 1))
      else print "(no extension)" }' | sort | uniq -c | sort -rn | head -10)
  if [ -n "$TYPES" ]; then echo "$TYPES" | sed 's/^/  /' >&2; else echo "  (no files)" >&2; fi
  echo >&2
  echo "A few filenames:" >&2
  find "$DIR" -type f -not -name '.*' 2>/dev/null | head -5 | sed "s|$DIR/|  |" >&2
  echo >&2
  echo "If your photos are there but in a format not listed above (HEIC, RAW," >&2
  echo "DNG, CR2...), that's the problem — say so and I'll add it." >&2
  exit 1
fi

if [ "$REVERSE" = 1 ]; then
  awk '{a[NR]=$0} END{for(i=NR;i>=1;i--) print a[i]}' "$LIST" > "$LIST.r"
  mv "$LIST.r" "$LIST"
fi

# ---- report what was found, grouped by folder -----------------------------
SECS=$(awk -v c="$COUNT" -v f="$FPS" 'BEGIN{printf "%.1f", c/f}')
CLOCK=$(awk -v s="$SECS" 'BEGIN{printf "%d:%02d", int(s/60), int(s)%60}')

echo "Project:  $(basename "$DIR")"
echo
sed "s|^$DIR/||" "$LIST" | awk -F/ '
  {
    dir = (NF > 1) ? substr($0, 1, length($0) - length($NF) - 1) : "(top level)"
    n[dir]++
    if (!(dir in first)) { first[dir] = $NF; order[++k] = dir }
    last[dir] = $NF
  }
  END {
    for (i = 1; i <= k; i++) {
      d = order[i]
      f = first[d]; l = last[d]
      gsub(/^.*timelapse_/, "", f); gsub(/-[0-9]+\..*$/, "", f); gsub(/-/, ":", f)
      gsub(/^.*timelapse_/, "", l); gsub(/-[0-9]+\..*$/, "", l); gsub(/-/, ":", l)
      printf "  %-22s %6d frames   %s - %s\n", d, n[d], f, l
    }
  }' | head -40

NDIRS=$(sed "s|^$DIR/||" "$LIST" | sed 's|/[^/]*$||' | uniq | wc -l | tr -d ' ')
[ "$NDIRS" -gt 40 ] && echo "  ... $((NDIRS - 40)) more folders ..."

echo
echo "frames:     $COUNT"
echo "frame rate: $FPS fps"
echo "duration:   ${SECS}s (${CLOCK})"
if [ "$REVERSE" = 1 ]; then echo "order:      REVERSED"; fi
echo "first:      $(head -1 "$LIST" | sed "s|$DIR/||")"
echo "last:       $(tail -1 "$LIST" | sed "s|$DIR/||")"
echo "output:     $OUT"
echo

if [ "$DRYRUN" = 1 ]; then
  echo "--- dry run, nothing encoded ---"
  exit 0
fi

# ---- stage a numbered sequence -------------------------------------------
# Frame names are timestamps spread across folders, so ffmpeg can't read them
# as a sequence. Symlink them in order as frame_000001.ext — no copy, no rename.
EXT=$(head -1 "$LIST" | sed 's/.*\.//')
EXTS=$(sed -E 's/.*\.//' "$LIST" | tr 'A-Z' 'a-z' | sort -u | tr '\n' ' ')
if [ "$(echo "$EXTS" | wc -w)" -gt 1 ]; then
  echo "note: mixed file types ($EXTS). Staging all as .$EXT — ffmpeg detects"
  echo "      format from content, so this normally works. Check the result."
fi

STAGE="$TMP/stage"
mkdir -p "$STAGE"
i=1
while IFS= read -r f; do
  ln -s "$f" "$(printf '%s/frame_%06d.%s' "$STAGE" "$i" "$EXT")"
  i=$((i + 1))
done < "$LIST"

# ---- encode ---------------------------------------------------------------
FILTERS=""
[ "$DEFLICKER" = 1 ] && FILTERS="deflicker,"
[ -n "$SCALE" ] && FILTERS="${FILTERS}scale=${SCALE}:-2:flags=lanczos,"
# Pad odd dimensions to even — H.264 requires it.
FILTERS="${FILTERS}pad=ceil(iw/2)*2:ceil(ih/2)*2"

echo "Encoding..."
ffmpeg -y -loglevel error -stats -framerate "$FPS" -i "$STAGE/frame_%06d.$EXT" \
  -vf "$FILTERS" -c:v libx264 -preset slow -crf "$CRF" \
  -pix_fmt yuv420p -movflags +faststart "$OUT"

echo
echo "Done: $OUT"
echo "size: $(du -h "$OUT" | cut -f1 | tr -d ' ')"
