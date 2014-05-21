#!/bin/bash

note_dir="./notes"
font=BlackChancery
size=1024
scale=1.0
w='.'

die() { echo "$@"; exit 1; }

usage() {
  cat<<EOS
usage: $0 [options] NAME
options:
  -n PATH   directory containing note files
  -s FLOAT  continent scale multiplier
  -w PATH   directory for intermediate files
EOS
  exit 1
}

args=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage ;;
    -n) shift; note_dir="$1" ;;
    -s) shift; scale="$1" ;;
    -w) shift; w="$1" ;;
    *) args+=("$1") ;;
  esac
  shift
done

n=${args[0]}
if [ -z "$n" ]; then
  die "expecting NAME argument"
fi

mkdir -p "$w" || die "could not create directory '$w'"

o="$n.jpg"
f_notes="$note_dir/$n-notes.txt"
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

echo "=== Processing continent $n"

r_notes="$w/render_notes-$n.png"
if [ ! -f "$r_notes" -o "$f_notes" -nt "$r_notes" ]; then
  echo "--- Rendering notes '$f_notes'"
  elm-render-notes -f "$font" \
    -i$size,$size -m$size,$size \
    -s $scale -o "$r_notes" "$f_notes"
fi

echo "--- Merging layers"
t_all="$w/temp_all-$n.png"
composite "$r_notes" "$f_merged" "$t_all"

convert "$t_all" -quality 75 "$o"
echo "=== Finished $o"

rm -f "$t_all"
