#!/bin/bash

# MIT License
#
# Copyright (c) 2025 Nate Berkopec
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Default values for start and end times
start_time=0
end_time=30

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--start)
            start_time="$2"
            shift 2
            ;;
        -e|--end)
            end_time="$2"
            shift 2
            ;;
        *)
            url="$1"
            shift
            ;;
    esac
done

# Check if URL is provided
if [ -z "$url" ]; then
    echo "Error: YouTube URL is required"
    echo "Usage: $0 [youtube_url] [-s|--start start_time] [-e|--end end_time]"
    exit 1
fi

# Store original directory
original_dir=$(pwd)

# Create temporary directory
temp_dir=$(mktemp -d)
cd "$temp_dir"

echo "Downloading video..."
# Download video using yt-dlp
yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" \
    --merge-output-format mp4 \
    -o "original.mp4" \
    "$url"

echo "Clipping video from $start_time to $end_time seconds..."
# Clip the video using ffmpeg
ffmpeg -i "original.mp4" -ss "$start_time" -t "$((end_time - start_time))" \
    -c:v libx264 -c:a aac "clipped.mp4"

echo "Converting to Twitter-optimized format..."
# Convert to Twitter-optimized format
# Twitter recommendations: H.264 video codec, AAC audio codec
# Max bitrate: 25 Mbps, recommended resolution: 1280x720
ffmpeg -i "clipped.mp4" \
    -c:v libx264 -preset medium -profile:v high -level:v 4.0 \
    -b:v 5M -maxrate 5M -bufsize 10M \
    -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:-1:-1:color=black" \
    -c:a aac -b:a 128k -ar 44100 \
    -pix_fmt yuv420p \
    -movflags +faststart \
    "${original_dir}/output.mp4"

# Clean up
cd "$original_dir"
rm -rf "$temp_dir"

echo "Done! Video has been saved as output.mp4"
