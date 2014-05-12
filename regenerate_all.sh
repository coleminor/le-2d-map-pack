#!/bin/bash
map_dir='../run/maps'
map_ext='.elm.gz'
note_dir='./notes'

sed_expr="s,^\\([^ ]*\\),$map_dir/\\1$map_ext,"
cat input_maps.txt \
  | sed -e "$sed_expr" \
  | while read l; do
  ./create_map.sh -n "$note_dir" $l || exit 1
done

./create_legend.sh
./create_continent.sh 1_seridia 2.0
./create_continent.sh 2_irilion 3.0
