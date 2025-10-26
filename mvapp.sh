#!/usr/bin/env bash
# Script para intercambiar ventanas entre workspaces en i3wm
# Funciona solo si el monitor DP-1 está conectado
if xrandr | grep "^DP-1 connected"; then
    from=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused==true).name')
    num=${from#0}
    to=$(printf "%02d" "$(( num <= 10 ? num + 10 : num - 10 ))")
    
    # Guardar IDs de ventanas originales de ambos workspaces
    wins_from=($(i3-msg -t get_tree | jq -r --arg ws "$from" '.. | objects | select(.type?=="workspace" and .name==$ws) | .. | objects | select(.window? and .window!=null) | .id'))
    wins_to=($(i3-msg -t get_tree | jq -r --arg ws "$to"   '.. | objects | select(.type?=="workspace" and .name==$ws)   | .. | objects | select(.window? and .window!=null) | .id'))
    
    # Mover ventanas usando las listas guardadas
    for w in "${wins_from[@]}"; do i3-msg "[con_id=$w]" move container to workspace number "$to" >/dev/null; done
    for w in "${wins_to[@]}";   do i3-msg "[con_id=$w]" move container to workspace number "$from" >/dev/null; done
fi
