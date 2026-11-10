#!/usr/bin/env python3
import os, re

FRAMES_DIR = '/etc/cryptsetup-initramfs/frames'

# Colores de fondo ANSI
WHITE  = '\033[47m'
GREEN  = '\033[42m'
RED    = '\033[41m'
BLUE   = '\033[44m'
BLACK  = '\033[40m'
RESET  = '\033[0m'

COLORS = {
    'M': WHITE,  'm': RED,
    'B': WHITE,  'b': WHITE,
    'C': WHITE,  'c': WHITE,
    'D': GREEN,  'd': GREEN,
    'E': GREEN,  'e': GREEN,
    'F': GREEN,  'f': GREEN,
    'A': WHITE,  'a': WHITE,
    'N': WHITE,  'n': RED,
    'O': WHITE,  'o': RED,
    'P': GREEN,  'p': RED,
    'Q': GREEN,  'q': RED,
    'R': GREEN,  'r': RED,
    's': RED,    'S': RED,
    't': RED,    'T': RED,
    'u': RED,    'U': RED,
    '0': BLUE,
    '1': BLUE,
    '2': BLUE,
}

def colorize_line(line):
    out = ''
    for ch in line.rstrip('\n'):
        if ch in COLORS:
            out += COLORS[ch] + ' ' + RESET
        elif ch == '#':
            out += BLACK + ' ' + RESET
        else:
            out += ch
    return out + '\n'

for fname in sorted(os.listdir(FRAMES_DIR)):
    if not re.match(r'^\d+\.txt$', fname):
        continue
    fpath = os.path.join(FRAMES_DIR, fname)
    with open(fpath, 'r') as f:
        lines = f.readlines()
    with open(fpath, 'w') as f:
        f.writelines(colorize_line(l) for l in lines)
    print(f'Coloreado: {fname}')

print('Listo.')
