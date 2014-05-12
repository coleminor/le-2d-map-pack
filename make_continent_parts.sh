#!/bin/bash
f=mapinfo.lst
map_dir=../run/maps

die() { echo "$@"; exit 1; }

usage() {
  cat<<EOS
usage: $0 NAME SCALE

NAME is the continent name as it appears
in the first column of '$f'.

SCALE is a floating point number that the
image sizes will be divided by. A scale of
1.0 implies 1 map tile to 1 pixel.
EOS
  exit 1
}

p=$1
s=$2
if [ -z "$p" -o -z "$s" ]; then
  usage
fi

sed -n -e 's,./maps/,,' -e 's,.elm\s*,,' \
  -e "/^$p[a-z]*\\s*[1-9]/p" "$f" \
  | awk '!/hallo|niege|valen|grotte|_int/ {print $6}' \
  | while read n; do
  r_map="render_map-$n.png"
  if [ ! -f "$r_map" ]; then
    die "rendered map '$r_map' not found"
  fi
  f_map="$map_dir/$n.elm.gz"
  if [ ! -f "$f_map" ]; then
    die "elm file '$f_map' not found"
  fi
  read x y <<<$(elmhdr "$f_map" \
    | awk "/^terrain_[xy]/ {print 6*\$3/$s}")
  o_map="part-$n.png"
  echo "--- Resizing $n to ${x}x$y"
  convert "$r_map" -resize ${x}x$y\! "$o_map"
done
