#!/bin/sh -e

##
## Stabilizes video
## (remove shakes and jitters of video shooted by hand-held cameras)
##
## Since avconv often fail to read or write files with colons,
## and on the other hand avconv input and output formats are in
## depend of input file and output file extensions, I've to
## use symlinks and temporary files.
## Tested on Debian Jessie with avconv from deb-multimedia repository.
##
## TODO: use transcode when available because avconv was excluded
## from Ubuntu and libav-tools-links package provides only symlinks
## to the ffmpeg tool. Simulated avconv interface cannot stabilize
## video.
##
## All progress information is redirected to /tmp/stab.log.
##

if [ $# -gt 1 ]; then
    while [ -n "$1" ]; do
        "$0" "$1"
        shift
    done
    exit 0
fi

[ -f "$1" ] || { echo "Usage: $0 clip1 [clip2 [...]]"; exit 1; }
datetime(){ date '+%Y-%m-%d %H:%M:%S'; }
echo "Stabilizing $1:"
EXT=`basename "$1" | rev | cut -d. -f1 -s | rev`
ABS_NAME=`readlink -f "$1"`
ln -sf -- "$ABS_NAME" /tmp/video."$EXT"
> /tmp/stab.log
echo -n "   `datetime` Calculating transformations..."
if [ -x /usr/bin/transcode2 ]; then
    # Ubuntu
    transcode -J stabilize=shakiness=8 \
        -i /tmp/video."$EXT" \
        -y null,null \
        -o dummy >> /tmp/stab.log 2>&1 || \
        { echo "FAILED. See /tmp/stab.log for details"; exit 1; }
    echo -n "DONE\n   `datetime` Rendering..."
    transcode -J transform -i /tmp/video."$EXT" \
        -y xvid \
        -o /tmp/stab."$EXT" || \
        { echo "FAILED. See /tmp/stab.log for details"; exit 1; }
elif [ -x /usr/bin/avconv ]; then
    # Debian. avconv from the deb-multimedia project
    avconv -i /tmp/video."$EXT" \
        -filter:v vidstabdetect=result=/tmp/trf:shakiness=10 \
        -f null /dev/null >> /tmp/stab.log 2>&1 || \
        { echo "FAILED. See /tmp/stab.log for details"; exit 1; }
    echo -n "DONE\n   `datetime` Rendering..."
    avconv -i /tmp/video."$EXT" \
        -filter:v vidstabtransform=input=/tmp/trf -y \
        /tmp/stab."$EXT" >> /tmp/stab.log 2>&1 || \
        { echo "FAILED. See /tmp/stab.log for details"; exit 1; }
else
    echo "FAILED. No converter found."
    exit 1
fi
echo "DONE\n   `datetime` Moving temporary file..."
mv -f -- /tmp/stab."$EXT" \
   "`dirname "$1"`"/"`basename "$1" ."$EXT"`"_stabilized."$EXT"
echo "   `datetime` DONE"
