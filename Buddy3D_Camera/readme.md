# timelapse.sh

Turns a folder of camera stills into a timelapse video. Point it at a project
folder and it handles the rest — no renaming, no sorting, no per-day passes.

```bash
./timelapse.sh ~/Pictures/myproject
```

```
Project:  myproject

  20250813                   14 frames   06:30:00 - 06:36:30
  20250814                    9 frames   06:30:00 - 06:34:00
  20250815                   11 frames   06:30:00 - 06:35:00
  20250902                    6 frames   06:30:00 - 06:32:30

frames:     40
frame rate: 30 fps
duration:   1.3s (0:01)
output:     ~/Pictures/myproject/myproject.mp4
```

## Requirements

macOS or Linux, plus ffmpeg:

```bash
brew install ffmpeg
```

Works with the bash 3.2 that ships with macOS — no newer shell needed.

## Install

```bash
chmod +x timelapse.sh
```

## Expected layout

The camera writes one folder per day, each holding timestamped frames:

```
myproject/
  20250813/
    timelapse_06-30-00-000.jpg
    timelapse_06-30-30-000.jpg
  20250814/
    timelapse_06-30-00-000.jpg
```

Any nesting depth works, including frames sitting loose in the project folder
with no day folders at all.

## Usage

```
timelapse.sh [options] <project folder>
```

| Option | Meaning |
| --- | --- |
| `-r FPS` | Frame rate, default `30`. Lower means a longer video. |
| `-s WIDTH` | Scale to WIDTH px wide, height automatic. Omit for source resolution. |
| `-o FILE` | Output path. Default `<project folder>/<name>.mp4`. |
| `-q CRF` | Quality, 0–51, lower is better. Default `18`; `23` gives a smaller file. |
| `-d` | Deflicker, for frames that pulse from auto-exposure. |
| `-x` | Reverse the sequence. |
| `-n` | Dry run — print what was found, encode nothing. |
| `-h` | Help. |

### Examples

```bash
# See what it found before committing to an encode
./timelapse.sh -n ~/Pictures/myproject

# 1080p at 24fps
./timelapse.sh -r 24 -s 1920 ~/Pictures/myproject

# Smaller file, custom destination
./timelapse.sh -q 23 -s 1280 -o ~/Movies/site-a.mp4 ~/Pictures/myproject
```

## How ordering works

Frames are ordered by a plain lexicographic sort of their full path. Both
naming conventions already sort chronologically — `YYYYMMDD` folders oldest
first, `timelapse_HH-MM-SS-mmm` files earliest first — so the sort alone puts
every frame in the right place regardless of how deep the tree goes.

ffmpeg can't read timestamped filenames as a sequence, so the script symlinks
them in order as `frame_000001.jpg` in a temp directory and encodes from there.
**Your originals are never renamed, moved, or modified.** The temp directory is
removed on exit.

## Choosing a frame rate

Frame rate sets the length: at 30fps, 900 photos gives 30 seconds.

| Frames | at 24fps | at 30fps |
| --- | --- | --- |
| 300 | 12.5s | 10s |
| 900 | 37.5s | 30s |
| 1800 | 75s | 60s |

Below roughly 20fps the result starts to look choppy. If a project comes out
too short, lower `-r` before considering a reshoot.

## Troubleshooting

**"found 0 usable photo(s)"** — the script prints what it actually saw: the
subfolders, the file types present, and a few sample filenames. That output
normally identifies the problem on its own.

```
File types present:
        3 heic
        1 cr2
```

**HEIC or RAW files.** Only JPEG, PNG, and TIFF are searched. HEIC and camera
RAW (CR2, NEF, ARW, DNG) are skipped, and HEIC needs a decoder that Homebrew's
stock ffmpeg often lacks. Convert first:

```bash
# HEIC -> JPEG alongside the originals, using macOS's built-in converter.
# Writes photo.jpg next to photo.heic and leaves the originals untouched.
find ~/Pictures/myproject -iname '*.heic' | while IFS= read -r f; do
  sips -s format jpeg "$f" --out "${f%.*}.jpg"
done
```

**Flicker.** `-d` applies ffmpeg's deflicker filter, which is a partial fix at
best. Shooting in full manual exposure is the real answer; LRTimelapse is the
serious tool for repairing it afterward.

**Mixed file types.** The script warns and stages everything under one
extension. ffmpeg detects format from content so this usually works, but check
the result.

**`._filename.jpg` files.** macOS writes AppleDouble stubs alongside real files
on SD cards and other non-native volumes. They match an image glob but aren't
images and would break the encode. The script skips them, along with all other
dotfiles.

## Notes

- Output is H.264 in MP4, `yuv420p`, with `+faststart` for web playback.
- Odd frame dimensions are padded to even, which H.264 requires.
- Scaling uses Lanczos.
- A slower shutter on capture produces motion blur that makes the result
  smoother. Nothing can add that afterward.
