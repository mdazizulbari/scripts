#!/bin/bash

# run command 👇
# bash v2_make_shorts_mint.sh

# ============================================================
#  YouTube Shorts Builder — Linux Mint
#  Logic: ported from Windows Git Bash version
#  Syntax: native Linux bash (no Git Bash workarounds needed)
# ============================================================
 
# ── CONFIG ──────────────────────────────────────────────────
VIDEO_DIR="$HOME/Videos/Today"
input="videoplayback.mp4"
output="video_no_audio_speed.mp4"
image_path="$VIDEO_DIR/pic.png"
audio_path="$HOME/Videos/music12.mp3"
# ────────────────────────────────────────────────────────────
 
# returns 0 = skip this step, 1 = run this step
ask_skip() {
    local file="$1"
    if [ -f "$file" ]; then
        read -rp "⚠️  '$file' already exists. Skip? [Y/n]: " ans
        case "$ans" in
            [nN]*) return 1 ;;   # user said no → recreate
            *)     echo "⏭️  Skipping."; return 0 ;;  # default Enter or Y → skip
        esac
    fi
    return 1  # file doesn't exist → always run
}
 
cd "$VIDEO_DIR" || { echo "❌ Cannot find VIDEO_DIR: $VIDEO_DIR"; exit 1; }
 
# ── Step 1: Make the video 40s long ──────────────────────────
ask_skip "$output" || {
    duration=$(ffprobe -v error -show_entries format=duration \
               -of default=noprint_wrappers=1:nokey=1 "$input")
    speed_factor=$(echo "$duration / 40" | bc -l)
    ffmpeg -i "$input" -filter:v "setpts=PTS/$speed_factor" -an "$output"
}
 
# ── Step 2: Rotate 90° + scale to 1080x1920 ──────────────────
ask_skip "video_no_audio.mp4" || {
    ffmpeg -i "$output" \
      -vf "transpose=1,scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" \
      -c:a copy "video_no_audio.mp4"
}
 
# ── Step 2b: Rotate the thumbnail ────────────────────────────
ask_skip "image.png" || {
    ffmpeg -i "$image_path" -vf "transpose=1" "image.png"
}
 
# ── Step 3: Create 5s image video ────────────────────────────
ask_skip "image_video.mp4" || {
    ffmpeg -loop 1 -i "image.png" \
           -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" \
           -c:v libx264 -t 5 -r 30 -pix_fmt yuv420p image_video.mp4
}
 
# ── Step 4: Merge video + image ──────────────────────────────
ask_skip "combined_video_no_audio.mp4" || {
    > final_file_list.txt
    echo "file 'video_no_audio.mp4'" >> final_file_list.txt
    echo "file 'image_video.mp4'"    >> final_file_list.txt
    ffmpeg -f concat -safe 0 -i final_file_list.txt -c copy combined_video_no_audio.mp4
}
 
# ── Step 5: Add audio ─────────────────────────────────────────
ask_skip "final_video.mp4" || {
    ffmpeg -i combined_video_no_audio.mp4 -i "$audio_path" -shortest \
           -c:v copy -c:a aac -b:a 192k final_video.mp4
}
echo "🎉 Final MP4 created: final_video.mp4"
 
# ── Step 6: Vertical version ──────────────────────────────────
ask_skip "final_video_vertical.mp4" || {
    ffmpeg -i final_video.mp4 \
      -vf "transpose=2" \
      -c:a copy final_video_vertical.mp4
}
echo "📱 Vertical MP4 created: final_video_vertical.mp4"
 
# ── Cleanup ───────────────────────────────────────────────────
rm -f final_file_list.txt
 