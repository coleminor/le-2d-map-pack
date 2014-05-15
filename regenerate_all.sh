#!/bin/bash
map_dir='./maps'
map_ext='.elm.gz'
note_dir='./notes'

sed_expr="s,^\\([^ ]*\\),$map_dir/\\1$map_ext,"
cat input_maps.txt \
  | sed -e "$sed_expr" \
  | while read l; do
  ./create_map.sh -n "$note_dir" $l || exit 1
done

./create_legend.sh -n "$note_dir"
./create_continent.sh -n "$note_dir" -s 2.0 1_seridia
./create_continent.sh -n "$note_dir" -s 3.0 2_irilion
