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

if [[ -z "$1" ]]; then
  printf "%s\n" "${!LINKS[@]}"
  exit 0
fi

choice="$1"

if [[ -n "${LINKS[$choice]}" ]]; then
  xdg-open "${LINKS[$choice]}"
  exit 0
fi

# 2. Si no existe → buscar en Firefox
query=$(printf "%s" "$choice" | sed 's/ /+/g')

firefox "https://duckduckgo.com/?q=$query" &
exit 0
