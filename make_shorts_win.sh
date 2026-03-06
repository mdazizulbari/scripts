#!/bin/bash

# runcommand 👇
# bash make_shorts_win.sh 

# ============================================================
#  YouTube Shorts Builder — Windows Git Bash
#  Logic: identical to Linux script (single video workflow)
#  Syntax: Windows-compatible paths & temp file handling
# ============================================================

# ── CONFIG ──────────────────────────────────────────────────
VIDEO_DIR="C:/Users/SMA Desk/Videos/Today"   # CHANGED: Windows path with forward slashes
input="videoplayback.mp4"
output="video_no_audio_speed.mp4"
image_path="$VIDEO_DIR/pic.png"              # CHANGED: full path needed on Windows
audio_path="C:/Users/SMA Desk/Videos/music13.mp3"  # CHANGED: Windows path
# ────────────────────────────────────────────────────────────

# CHANGED: cd into video dir so all relative file refs work
cd "$VIDEO_DIR" || { echo "❌ Cannot find VIDEO_DIR: $VIDEO_DIR"; exit 1; }

# ── Step 1: Make the video 40s long ──────────────────────────
duration=$(ffprobe -v error -show_entries format=duration \
           -of default=noprint_wrappers=1:nokey=1 "$input")
speed_factor=$(echo "$duration / 40" | bc -l)
ffmpeg -y -i "$input" -filter:v "setpts=PTS/$speed_factor" -an "$output"

# ── Step 2: Rotate 90° + scale to 1080x1920 ──────────────────
ffmpeg -y -i "$output" \
  -vf "transpose=1,scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" \
  -c:a copy "video_no_audio.mp4"

# ── Step 2b: Rotate the thumbnail ────────────────────────────
ffmpeg -y -i "$image_path" -vf "transpose=1" "image.png"

# ── Step 3: Create 5s image video ────────────────────────────
ffmpeg -y -loop 1 -i "image.png" \
       -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" \
       -c:v libx264 -t 5 -r 30 -pix_fmt yuv420p image_video.mp4

# ── Step 4: Merge video + image ──────────────────────────────
# CHANGED: explicitly clearing and writing concat list to avoid stale entries
> final_file_list.txt
echo "file 'video_no_audio.mp4'" >> final_file_list.txt
echo "file 'image_video.mp4'"    >> final_file_list.txt
ffmpeg -y -f concat -safe 0 -i final_file_list.txt -c copy combined_video_no_audio.mp4

# ── Step 5: Add audio ─────────────────────────────────────────
ffmpeg -y -i combined_video_no_audio.mp4 -i "$audio_path" -shortest \
       -c:v copy -c:a aac -b:a 192k final_video.mp4
echo "🎉 Final MP4 created: final_video.mp4"

# ── Step 6: Vertical version ──────────────────────────────────
ffmpeg -y -i final_video.mp4 \
  -vf "transpose=2" \
  -c:a copy final_video_vertical.mp4
echo "📱 Vertical MP4 created: final_video_vertical.mp4"

# ── Cleanup ───────────────────────────────────────────────────
rm -f final_file_list.txt