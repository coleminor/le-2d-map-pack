#!/bin/bash

i_paper="legend_paper.png"
font=BlackChancery

die() { echo "$@"; exit 1; }

n=legend
o="$n.jpg"
f_notes="$n-notes.txt"
r_notes="render_notes-$n.png"

if [ -f "$o" -a "$o" -nt "$f_notes" ]; then
  echo "~~~ $o is up-to-date"
  exit
fi

if [ ! -f "$r_notes" -o "$f_notes" -nt "$r_notes" ]; then
  echo "--- Rendering $f_notes"
  read x y <<<$(identify -format '%W %H' "$i_paper")
  if [ -z "$x" -o -z "$y" ]; then
    die "$i_paper: could not get image size"
  fi
  elm-render-notes -f "$font" -i $x,$y -t 50 \
    -m $x,$y -o "$r_notes" "$f_notes" || exit 1
fi

echo "--- Merging layers"
composite "$r_notes" "$i_paper" "$o"

echo "=== Finished $o"
