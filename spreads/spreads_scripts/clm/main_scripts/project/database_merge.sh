#!/bin/bash

# This script merges databases for assimilation

log "Merging databases..."

if [ -d "$TMPROOT/allTS" ]; then
    rm -rf "$TMPROOT/allTS"
fi

rm -rf files_db.txt
ls TS*/*.?.db | sed 's@TS.*/@@g' > files_db.txt
for f in $(sort files_db.txt | uniq); do
    ./d4ojoin $(find TS*/ -name "$f" | head -n 1)
done

log "Database merging completed."
