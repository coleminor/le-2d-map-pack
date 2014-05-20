#!/bin/bash
f=mapinfo.lst
map_dir=./maps
c=Seridia
s=1.0
w='.'

die() { echo "$@"; exit 1; }

usage() {
  cat<<EOS
Usage: $0 OPTIONS
Options:
  -i PATH   path to '$f'
  -c NAME   continent name in '$f'
  -s FLOAT  divide image sizes by this
  -w PATH   directory containing rendered maps

NAME is the continent name as it appears
in the first column of '$f'.

The -s option takes a floating point number that
the image sizes will be divided by. A scale of
1.0 implies 1 map tile to 1 pixel.
EOS
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

args=()
while [ $# -gt 0 ]; do
  case "$1" in
    -c) shift; c="$1" ;;
    -h|--help) usage ;;
    -i) shift; f="$1" ;;
    -s) shift; s="$1" ;;
    -w) shift; w="$1" ;;
    *) args+=("$1") ;;
  esac
  shift
done

if [ ${#args[@]} -gt 0 ]; then
  usage
fi

if [ ! -f "$f" ]; then
  die "file not found: '$f'"
fi

sed -n -e 's,./maps/,,' -e 's,.elm\s*,,' \
  -e "/^$c[a-z]*\\s*[1-9]/p" "$f" \
  | awk '!/hallo|niege|valen|grotte|_int/ {print $6}' \
  | while read n; do
  r_map="$w/render_map-$n.png"
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
