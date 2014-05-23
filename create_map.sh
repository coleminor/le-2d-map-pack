#!/bin/bash

font="BlackChancery"

note_dir="./notes"
remove_temporary_files=1
smooth_mask=0
black_background=0
solid_color_terrain=0
textured_terrain=0
force=0
delete_rendered=0
w='.'

size=1024
color_size_limit=192
i_rect="rect.png"
i_grid="grid.png"
i_paper="paper.png"

die() { echo "$@";  exit 1; }

usage() {
  c=$color_size_limit
  cat<<EOS
Usage: $0 [options] ELM-FILES
Options:
  -b       render on a black background
  -c       use solid terrain colors
  -d       delete rendered images afterwards
  -f       force regeneration of images
  -k       keep temporary files
  -n PATH  directory containing note files
  -s       shrink and smooth mask
  -t       use terrain textures
  -w PATH  directory for intermediate files

If neither options -c or -t are used, maps
with more than $c tiles per side will be
rendered with solid color terrains.
EOS
  exit 1
}

args=()
while [ $# -gt 0 ]; do
  case "$1" in
    -b) black_background=1 ;;
    -c) solid_color_terrain=1 ;;
    -d) delete_rendered=1 ;;
    -f) force=1 ;;
    -h|--help) usage ;;
    -k) remove_temporary_files=0 ;;
    -n) shift; note_dir="$1" ;;
    -s) smooth_mask=1 ;;
    -t) textured_terrain=1 ;;
    -w) shift; w="$1" ;;
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

s_render=
s_render+=b$black_background
s_render+=c$solid_color_terrain
s_render+=t$textured_terrain

s_mask=
s_mask+=b$black_background
s_mask+=s$smooth_mask

mkdir -p "$w" || die "could not create directory '$w'"

for p in "${args[@]}"; do
  if [ ! -f "$p" ]; then
    die "$p: no such file"
  fi
  read f <<<$(basename "$p")
  n=${f/.gz/}
  n=${n/.elm/}
  if [ "$n" = "$f" ]; then
    die "$p: not a map file"
  fi
  o="$n.jpg"

  f_render_settings="$w/settings_render-$n.txt"
  d_render=0
  if [ -f "$f_render_settings" ]; then
    read s_old < "$f_render_settings"
    if [ "$s_render" != "$s_old" ]; then
      d_render=1
    fi
  fi
  if [ $force -eq 1 ]; then
    d_render=1
  fi
  echo "$s_render" > "$f_render_settings"

  f_mask_settings="$w/settings_mask-$n.txt"
  d_mask=0
  if [ -f "$f_mask_settings" ]; then
    read s_old < "$f_mask_settings"
    if [ "$s_mask" != "$s_old" ]; then
      d_mask=1
    fi
  fi
  if [ $force -eq 1 ]; then
    d_mask=1
  fi
  echo "$s_mask" > "$f_mask_settings"

  f_notes="$note_dir/$n-notes.txt"
  if [ $d_render -eq 0 -a -f "$o" -a "$o" -nt "$p" \
      -a "$o" -nt "$f_notes" -a "$o" -nt "$i_paper" \
      -a "$o" -nt "$i_grid" -a "$o" -nt "$i_rect" ]; then
    echo "~~~ $o is up-to-date"
    continue
  fi

  e=elmhdr
  if ! which "$e" > /dev/null; then
    die "required program '$e' missing or not executable"
  fi
  read x y <<<$("$e" "$p" \
    | awk '/^terrain_[xy] = [0-9]+/ {print 6*$3}')
  if [ -z "$x" -o -z "$y" ]; then
    die "could not get map size from '$p'"
  fi
  echo "=== Processing $n ${x}x$y $s_render $s_mask"

  r_map="$w/render_map-$n.png"
  t_pov="$w/temp_scene-$n.pov"
  if [ $d_render -eq 1 -o ! -f "$r_map" \
      -o "$p" -nt "$r_map" ]; then
    a_s=
    a_t=
    if [ $solid_color_terrain -eq 1 ]; then
      a_s=-S
    fi
    if [ $textured_terrain -eq 1 ]; then
      a_s=
    fi
    if [ $solid_color_terrain -eq 0 \
        -a $textured_terrain -eq 0 ]; then
      c=$color_size_limit
      if [ $x -gt $c -o $y -gt $c ]; then
        a_s=-S
      fi
    fi
    if [ $black_background -eq 0 ]; then
      a_t=-t
    fi
    echo "--- Running elm2pov.pl"
    if [ -f "$r_map" ]; then
      rm -f "$r_map" || exit 1
    fi
    elm2pov.pl -r -m -a -s $size $a_s $a_t \
      -o "$r_map" -p "$t_pov" "$p" || exit 1
    if [ ! -f "$r_map" ]; then
      die "failed to create rendered map '$r_map'"
    fi
  fi

  r_notes="$w/render_notes-$n.png"
  if [ $force -eq 1 -o ! -f "$r_notes" \
      -o "$f_notes" -nt "$r_notes" ]; then
    if [ -f "$f_notes" ]; then
      echo "--- Rendering notes '$f_notes'"
      elm-render-notes -f "$font" -i$size,$size \
        -m$x,$y -o "$r_notes" "$f_notes" || exit 1
    fi
  fi

  r_mask="$w/render_mask-$n.png"
  if [ $d_mask -eq 1 -o ! -f "$r_mask" \
      -o "$p" -nt "$r_mask" \
      -o "$i_rect" -nt "$r_mask" ]; then
    echo "--- Creating mask"

    t_fill="$w/temp_fill-$n.png"
    convert "$r_map" -alpha extract "$t_fill"

    t_region="$w/temp_region-$n.png"
    if [ $smooth_mask -eq 1 ]; then
      t_tiles="$w/temp_tiles-$n.png"
      elm-draw-tiles -s $size,$size \
        -o "$t_tiles" "$p" || exit 1

      l=$(($x < $y ? $x : $y))
      d=`echo "6 * $size / $l" | bc -l`
      t_near="$w/temp_near-$n.png"
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

  r_texture="$w/render_paper_texture.png"
  if [ $force -eq 1 -o ! -f "$r_texture" \
      -o "$i_paper" -nt "$r_texture" ]; then
    echo "--- Creating paper texture"
    convert "$i_paper" -colorspace gray "$r_texture"
  fi
  r_bumpy="$w/render_bumpy-$n.png"
  if [ $d_render -eq 1 -o ! -f "$r_bumpy" \
      -o "$r_map" -nt "$r_bumpy" \
      -o "$r_texture" -nt "$r_bumpy" ]; then
    echo "--- Applying bumpmap"
    convert "$r_map" "$r_texture" \
      -compose bumpmap -composite \
      -brightness-contrast 30x40 "$r_bumpy"
  fi

  echo "--- Merging layers"
  r_base="$w/render_base-$n.png"
  if [ $d_render -eq 1 -o ! -f "$r_base" \
      -o "$r_bumpy" -nt "$r_base" \
      -o "$i_paper" -nt "$r_base" \
      -o "$r_mask" -nt "$r_base" ]; then
    composite "$r_bumpy" "$i_paper" "$r_mask" "$r_base"
  fi
  t_framed="$w/temp_framed-$n.png"
  composite -dissolve 60 "$i_grid" "$r_base" "$t_framed"
  t_all="$w/temp_all-$n.png"
  if [ -f "$r_notes" ]; then
    composite "$r_notes" "$t_framed" "$t_all"
  else
    cp "$t_framed" "$t_all"
  fi

  convert "$t_all" -quality 75 "$o"
  echo "=== Finished $o"

  if [ $remove_temporary_files -eq 1 ]; then
    rm -f "$t_fill" "$t_tiles" "$t_near" \
      "$t_region" "$t_framed" "$t_all" "$t_pov"
  fi
  if [ $delete_rendered -eq 1 ]; then
    rm -f "$r_map" "$r_notes" "$r_mask" \
      "$r_texture" "$r_bumpy" "$r_base"
  fi
done
