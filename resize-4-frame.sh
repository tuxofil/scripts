#!/bin/sh -e

##
## Convert images for digital photo frame:
## resize, auto-orient and rename to names allowed
## by the FAT filesystems.
##

if [ -z "$1" -o -z "$2" ]; then
    echo "Usage: $0 <from-dir> <to-dir>" >&2
    exit 1
fi

mkdir -p "$2"
for i in "$1"/*; do
    [ -f "$i" ] || continue
    # Fix name
    NAME=`basename "$i"`
    echo "$NAME" | grep -q -E -i '\.(jpe?g|png)$' || continue
    NEWNAME=`echo "$NAME" | sed 's/:/_/g'`
    echo -n "$NAME -> $2/$NEWNAME ..."
    # Do conversion
    convert "$i" -resize 800x600 -auto-orient "$2/$NEWNAME"
    echo " OK"
done
