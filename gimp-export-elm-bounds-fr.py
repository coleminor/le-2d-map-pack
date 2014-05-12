#!/usr/bin/env python

from gimpfu import *
from os.path import splitext
import re

image_width = 0
image_height = 0
continent_width = 512
continent_height = 512
continent_name = ''

def find_layer(i, n):
    for l in i.layers:
        if l.name == n:
            return l

def convert_coordinates(x, y):
    w = continent_width
    h = continent_height
    u = x * w / image_width
    v = h - y * h / image_height
    return u, v

def convert_rectangle(l):
    x, y = l.offsets
    w, h = l.width, l.height
    x0, y0 = convert_coordinates(x, y)
    x1, y1 = convert_coordinates(x + w, y + h)
    if x0 > x1:
        x0, x1 = x1, x0
    if y0 > y1:
        y0, y1 = y1, y0
    return x0, y0, x1, y1

def export_layer_bounds(l, f):
    s = continent_name
    t = convert_rectangle(l)
    s += ' %d %d %d %d ' % t
    n = re.sub(r'^part-(.*)\.png$',
        r'./maps/\1.elm', l.name)
    s += n + '\n'
    f.write(s)

def export_elm_bounds(i, d):
    global image_width
    global image_height
    global continent_name
    image_width = i.width
    image_height = i.height
    g = find_layer(i, 'parts')
    n = splitext(i.name)[0]
    n = re.sub('^parts-', '', n)
    c = re.sub('^[0-9]_', '', n)
    continent_name = c.capitalize()
    o = 'mapinfo_lst-' + n + '.txt'
    with open(o, 'w') as f:
        for l in g.children:
            export_layer_bounds(l, f)

register(
    'export_elm_bounds_fr',
    'Export ELM part layer bounds FR',
    'Converts and saves layer rectangle bounds'
    ' for all layers in the "parts" group,'
    ' for Landes-Eternelles continent maps.',
    'Cole Minor',
    'GPL3',
    '2014',
    '<Image>/Filters/Utility/Export ELM bounds FR',
    '*',
    [],
    [],
    export_elm_bounds,
)

main()
