#!/bin/bash

font=BlackChancery
s=1024

die() { echo "$@"; exit 1; }

n=$1
scale=$2
if [ -z "$n" -o -z "$scale" ]; then
  die "usage: $0 NAME SCALE"
fi

o="$n.jpg"
f_notes="$n-notes.txt"
f_merged="merged-$n.png"

if [ ! -f "$f_notes" ]; then
  die "note file '$f_notes' not found"
fi
if [ ! -f "$f_merged" ]; then
  die "required image '$f_merged' not found"
fi

if [ -f "$o" -a "$o" -nt "$f_notes" \
    -a "$o" -nt "$f_merged" ]; then
  echo "~~~ $o is up-to-date"
  exit 0
fi

r_notes="render_notes-$n.png"
if [ ! -f "$r_notes" -o "$f_notes" -nt "$r_notes" ]; then
  echo "--- Rendering notes '$f_notes'"
  elm-render-notes -f "$font" -i$s,$s -m$s,$s \
    -s $scale -o "$r_notes" "$f_notes"
fi

echo "--- Merging layers"
t_all="temp_all-$n.png"
composite "$r_notes" "$f_merged" "$t_all"

convert "$t_all" -quality 75 "$o"
echo "=== Finished $o"

rm -f "$t_all"
