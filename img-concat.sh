#!/bin/sh

get_img_width(){
    local WIDTH=`identify -format '%w' -quiet "$1"`
    if [ "$?" != "0" -o -z "$WIDTH" ]; then
        echo "error: failed to get image width" >&2
        exit 1
    fi
    echo "$WIDTH"
}

get_img_height(){
    local HEIGHT=`identify -format '%h' -quiet "$1"`
    if [ "$?" != "0" -o -z "$HEIGHT" ]; then
        echo "error: failed to get image height" >&2
        exit 1
    fi
    echo "$HEIGHT"
}

get_max(){
    local NUM1="$1"
    local NUM2="$2"
    if [ "$NUM1" -gt "$NUM2" ]; then
        echo "$NUM1"
    else
        echo "$NUM2"
    fi
}

do_img_concat(){
    local IMG1="$1"
    local IMG2="$2"
    local IMG_RES="$3"
    # Fetch source image dimensions
    IMG1_WIDTH=`get_img_width "$IMG1"`
    IMG1_HEIGHT=`get_img_height "$IMG1"`
    IMG2_WIDTH=`get_img_width "$IMG2"`
    IMG2_HEIGHT=`get_img_height "$IMG2"`
    # Calculate result image dimensions
    RES_WIDTH=`get_max "$IMG1_WIDTH" "$IMG2_WIDTH"`
    RES_HEIGHT=`expr "$IMG1_HEIGHT" + "$IMG2_HEIGHT"`
    # Generate temporary filename
    TMP_FILE="${IMG_RES}.tmp"
    rm -f "$TMP_FILE"
    convert "$IMG1" -extent "${RES_WIDTH}x${RES_HEIGHT}" "$TMP_FILE"
    composite -gravity South "$IMG2" "$TMP_FILE" "$IMG_RES"
    rm -f "$TMP_FILE"
}

set -e

if [ -z "$1" -o -z "$2" ]; then
    echo "Usage: $0 <img1> <img2> [<img3> [<img4> ...]] > <result_file>" >&2
    exit 1
fi

SRC=/tmp/`basename "$1"`.tmp
cp "$1" "$SRC"
while :; do
    shift
    [ -z "$1" ] && break
    do_img_concat "$SRC" "$1" "${SRC}.tmp"
    mv "${SRC}.tmp" "$SRC"
done
[ -f "$SRC" ] && cat "$SRC"
rm -f "$SRC"
