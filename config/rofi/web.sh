#!/usr/bin/env bash

declare -A LINKS=(
	["claude"]="https://claude.ai/new|icons/claude.ico"
	["whatsapp"]="https://web.whatsapp.com|icons/whatsapp.ico"
	["discord"]="https://discord.com/app|icons/discord.ico"
	["chatgpt"]="https://chat.openai.com|icons/chatgpt.ico"
	["campus"]="https://campusvirtual.uclm.es|icons/campusvirtual.ico"
	["github"]="https://github.com|icons/github.ico"
	["youtube"]="https://youtube.com|icons/youtube.ico"
)

# Si no hay argumento → listar opciones (para rofi/wofi/etc.)
if [[ -z "$1" ]]; then
	for key in "${!LINKS[@]}"; do
		IFS='|' read -r url icon <<< "${LINKS[$key]}"
		printf "%s\0icon\x1f%s\n" "$key" "$icon"
	done
	exit 0
fi

choice="$1"

# Si existe en el diccionario → abrir URL
if [[ -n "${LINKS[$choice]}" ]]; then
	IFS='|' read -r url icon <<< "${LINKS[$choice]}"
	setsid -f xdg-open "$url" >/dev/null 2>&1
	exit 0
fi

# Si no existe → buscar en Firefox (DuckDuckGo)
query=$(printf "%s" "$choice" | sed 's/ /+/g')

setsid -f firefox "https://duckduckgo.com/?q=$query" >/dev/null 2>&1
exit 0
