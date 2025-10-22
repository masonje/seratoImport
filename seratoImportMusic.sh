#!/bin/bash
set -euo pipefail

FILE_TYPES=("mp3" "flac" "wav" "m4a" "aac" "ogg")

SEARCH_DIR=~/Music/
DESC="~/Music/_Serato_/Auto Import"

SOURCE_DIR=$(eval echo "$SEARCH_DIR")
DEST_DIR=$(eval echo "$DESC")
IMP_LIST=$SOURCE_DIR/imported_files.txt
mkdir -p "$DEST_DIR"

# Build find-friendly arguments as an array so each -iname is a separate arg
FIND_ARGS=()
for type in "${FILE_TYPES[@]}"; do
    FIND_ARGS+=( -iname "*.${type}" -o )
done

# remove trailing -o
if [ "${#FIND_ARGS[@]}" -gt 0 ]; then
    unset 'FIND_ARGS[${#FIND_ARGS[@]}-1]'
else
    echo "No file types configured" >&2
    exit 1
fi

find "$SOURCE_DIR" -type f \( "${FIND_ARGS[@]}" \) -print0 | while IFS= read -r -d '' src; do
    echo "Processing: $src"
    base=$(basename "$src")
    dest="$DEST_DIR/$base"

    # skip files already recorded as imported
    if [ -f "$IMP_LIST" ] && grep -Fqx -- "$src" "$IMP_LIST"; then
        echo "Already imported: $src"
        continue
    fi

    if [ -e "$dest" ]; then
        if [ "$(readlink -f "$dest" 2>/dev/null)" = "$(readlink -f "$src" 2>/dev/null)" ]; then
            continue
        fi
        name="${base%.*}"
        ext="${base##*.}"
        i=1
        while [ -e "$DEST_DIR/${name}_$i.$ext" ]; do i=$((i+1)); done
        dest="$DEST_DIR/${name}_$i.$ext"
    fi

    #ln -s "$src" "$dest"
    cp --preserve=timestamps "$src" "$dest"
    echo "$src" >> "$IMP_LIST"

done

echo " "
echo "***************************************"
echo "Launch Serato to complete import."
echo "***************************************"
echo " "

# End of script