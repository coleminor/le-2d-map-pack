#!/bin/bash

font="BlackChancery"

note_dir="./notes"
remove_temporary_files=1
smooth_mask=0
transparent_background=1
solid_color_terrain=-1
force=0
delete_rendered=0

size=1024
small_size_cutoff=384
i_rect="rect.png"
i_grid="grid.png"
i_paper="paper.png"

die() {
  echo "$@"
  exit 1
}

usage() {
  cat<<EOS
usage: $0 [options] ELM-FILES
options:
  -b       render on a black background
  -c       use solid terrain colors
  -d       delete rendered images afterwards
  -f       force regeneration of images
  -k       keep temporary files
  -n PATH  directory containing note files
  -s       shrink and smooth mask
  -t       use terrain textures
EOS
  exit 1
}

args=()
while [ $# -gt 0 ]; do
  case "$1" in
    -b) transparent_background=0 ;;
    -c) solid_color_terrain=1 ;;
    -d) delete_rendered=1 ;;
    -f) force=1 ;;
    -h|--help) usage ;;
    -k) remove_temporary_files=0 ;;
    -n) shift; note_dir="$1" ;;
    -s) smooth_mask=1 ;;
    -t) solid_color_terrain=0 ;;
    *) args+=("$1") ;;
  esac
  shift
done

n=${#args[@]}
if [ $n -lt 1 ]; then
  usage
fi

if [ ! -f "$i_rect" ]; then
  die "rectangle mask image '$i_rect' not found"
fi
if [ ! -f "$i_grid" ]; then
  die "grid image '$i_grid' not found"
fi
if [ ! -f "$i_paper" ]; then
  die "paper texture image '$i_paper' not found"
fi

for p in "${args[@]}"; do
  if [ ! -f "$p" ]; then
    die "$p: no such file"
  fi
  f=`basename $p`
  n=${f/.gz/}
  n=${n/.elm/}
  if [ "$n" = "$f" ]; then
    die "$p: not a map file"
  fi

  o="$n.jpg"
  f_notes="$note_dir/$n-notes.txt"
  if [ $force -ne 1 -a -f "$o" -a "$o" -nt "$p" \
      -a "$o" -nt "$f_notes" -a "$o" -nt "$i_paper" \
      -a "$o" -nt "$i_grid" -a "$o" -nt "$i_rect" ]; then
    echo "~~~ $o is up-to-date"
    continue
  fi

  read x y <<<$(elmhdr "$p" \
    | awk '/^terrain_[xy] = [0-9]+/ {print 6*$3}')
  if [ -z "$x" -o -z "$y" ]; then
    die "$p: could not get map size"
  fi
  echo "=== Processing map $n (${x}x$y tiles)"

  r_map="render_map-$n.png"
  t_pov="temp_scene-$n.pov"
  if [ $force -eq 1 -o ! -f "$r_map" \
      -o "$p" -nt "$r_map" ]; then
    a_s=
    a_t=
    c=$small_size_cutoff
    s=$solid_color_terrain
    if [[ $s == 1 || ($s == -1 \
          && ($x > $c || $y > $c)) ]]; then
      a_s=-S
    fi
    if [ $transparent_background -eq 1 ]; then
      a_t=-t
    fi
    echo "--- Running elm2pov.pl"
    elm2pov.pl -r -m -a -s $size $a_s $a_t \
      -o "$r_map" -p "$t_pov" "$p" || exit 1
  fi

  r_notes="render_notes-$n.png"
  if [ $force -eq 1 -o ! -f "$r_notes" \
      -o "$f_notes" -nt "$r_notes" ]; then
    if [ -f "$f_notes" ]; then
      echo "--- Rendering notes '$f_notes'"
      elm-render-notes -f "$font" -i$size,$size \
        -m$x,$y -o "$r_notes" "$f_notes" || exit 1
    fi
  fi

  r_mask="render_mask-$n.png"
  if [ $force -eq 1 -o ! -f "$r_mask" \
      -o "$p" -nt "$r_mask" \
      -o "$i_rect" -nt "$r_mask" ]; then
    echo "--- Creating mask"

    t_fill="temp_fill-$n.png"
    convert "$r_map" -alpha extract "$t_fill"

    t_region="temp_region-$n.png"
    if [ $smooth_mask -eq 1 ]; then
      t_tiles="temp_tiles-$n.png"
      elm-draw-tiles -s $size,$size \
        -o "$t_tiles" "$p" || exit 1

      l=$(($x < $y ? $x : $y))
      d=`echo "6 * $size / $l" | bc -l`
      t_near="temp_near-$n.png"
      convert "$t_tiles" -blur 0x$d -threshold 1% \
        -blur 0x32 -threshold 50% \
        -blur 0x5 "$t_near"

      convert "$t_near" "$t_fill" \
        -compose darken -composite "$t_region"
    else
      cp "$t_fill" "$t_region"
    fi

    convert "$t_region" "$i_rect" \
      -compose darken -composite "$r_mask"
  fi

  echo "--- Merging layers"
  r_texture="render_paper_texture.png"
  if [ ! -f "$r_texture" -o "$i_paper" -nt "$r_texture" ]; then
    convert "$i_paper" -colorspace gray "$r_texture"
  fi
  t_bumpy="temp_bumpy-$n.png"
  convert "$r_map" "$r_texture" \
    -compose bumpmap -composite \
    -brightness-contrast 30x40 "$t_bumpy"
  t_base="temp_base-$n.png"
  composite "$t_bumpy" "$i_paper" "$r_mask" "$t_base"
  t_framed="temp_framed-$n.png"
  composite -dissolve 60 "$i_grid" "$t_base" "$t_framed"
  t_all="temp_all-$n.png"
  if [ -f "$r_notes" ]; then
    composite "$r_notes" "$t_framed" "$t_all"
  else
    cp "$t_framed" "$t_all"
  fi

  convert "$t_all" -quality 75 "$o"
  echo "=== Finished $o"

  if [ $remove_temporary_files -eq 1 ]; then
    rm -f "$t_fill" "$t_tiles" "$t_near" \
      "$t_region" "$t_bumpy" "$t_base" "$t_framed" \
      "$t_all" "$t_pov"
  fi
  if [ $delete_rendered -eq 1 ]; then
    rm -f "$r_map" "$r_notes" "$r_mask" "$r_texture"
  fi
done
