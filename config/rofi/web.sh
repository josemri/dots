#!/usr/bin/env bash

declare -A LINKS=(
  ["whatsapp"]="https://web.whatsapp.com"
  ["discord"]="https://discord.com/app"
  ["chatgpt"]="https://chat.openai.com"
  ["campus"]="https://campusvirtual.uclm.es"
  ["github"]="https://github.com"
  ["youtube"]="https://youtube.com"
  ["claude"]="https://claude.ai/new"
)
choice=$(printf "%s\n" "${!LINKS[@]}" | rofi -dmenu -i -p "Web")
[[ -n "$choice" ]] && xdg-open "${LINKS[$choice]}"

