#!/bin/bash

# Help function
show_help() {
cat << EOF
Usage: ${0##*/} [-u|--url] <YouTube-URL> [-n|--name] <Output-Base-Name>

This script downloads a video from YouTube using yt-dlp, extracts the audio,
converts it to MP3 format, and then splits the audio into multiple files, each 30 minutes long.

Options:
  -h|--help       Display this help and exit.
  -u|--url        Specify the YouTube URL to download.
  -n|--name       Base name for the output files.
EOF
}

# Initialize variables
URL=""
BASE_NAME=""

# Manual parsing for long options and help
for arg in "$@"; do
  shift
  case "$arg" in
    "--url")   set -- "$@" "-u" ;;
    "--name")  set -- "$@" "-n" ;;
    "--help")  set -- "$@" "-h" ;;
    *)         set -- "$@" "$arg"
  esac
done

# Parse options
while getopts "hu:n:" opt; do
  case ${opt} in
    h ) show_help; exit 0 ;;
    u ) URL=$OPTARG ;;
    n ) BASE_NAME=$OPTARG ;;
    \? ) show_help; exit 1 ;;
  esac
done

# Check if both arguments were provided
if [ -z "$URL" ] || [ -z "$BASE_NAME" ]; then
    show_help
    exit 1
fi

# Download with yt-dlp
yt-dlp -x --audio-format mp3 -o "${BASE_NAME}.%(ext)s" "${URL}"

# Check if yt-dlp succeeded
if [ $? -ne 0 ]; then
    echo "yt-dlp failed to download the audio."
    exit 1
fi

# Split the file with ffmpeg
ffmpeg -i "${BASE_NAME}.mp3" -f segment -segment_time 1800 -c copy "${BASE_NAME}%03d.mp3"

# Optional: Remove the original file if ffmpeg succeeded
if [ $? -eq 0 ]; then
    rm "${BASE_NAME}.mp3"
fi
