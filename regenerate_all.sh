#!/bin/bash
map_dir='./maps'
map_ext='.elm.gz'
note_dir='./notes'
work_dir='./work'

IFS=$'\n' read -d '' -r -a lines < input_maps.txt
set -e
for l in "${lines[@]}"; do
  read n a <<<$(echo "$l")
  f="$map_dir/$n$map_ext"
  ./create_map.sh -w "$work_dir" -n "$note_dir" "$f" $a
done
./create_legend.sh -w "$work_dir" -n "$note_dir"
./create_continent.sh -w "$work_dir" -n "$note_dir" -s 2.0 1_seridia
./create_continent.sh -w "$work_dir" -n "$note_dir" -s 3.0 2_irilion
