#!/usr/bin/env bash

ROFI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="$ROFI_DIR/web_custom"

declare -A LINKS=(
	["claude"]="https://claude.ai/new|icons/claude.ico"
	["whatsapp"]="https://web.whatsapp.com|icons/whatsapp.ico"
	["chatgpt"]="https://chat.openai.com|icons/chatgpt.ico"
	["campus"]="https://campusvirtual.uclm.es|icons/campusvirtual.ico"
	["github"]="https://github.com|icons/github.ico"
	["youtube"]="https://youtube.com|icons/youtube.ico"
	["telegram"]="https://web.telegram.org/a/|icons/telegram.ico"
)

if [[ -z "$1" ]]; then
	for key in "${!LINKS[@]}"; do
		IFS='|' read -r url icon <<< "${LINKS[$key]}"
		printf "%s\0icon\x1f%s\n" "$key" "$icon"
	done
	if [[ -f "$DATA" ]]; then
		while IFS=$'\t' read -r name url icon; do
			[[ -n "$name" ]] || continue
			if [[ -n "$icon" && -f "$ROFI_DIR/icons/$icon" ]]; then
				printf "%s\0icon\x1f%s\n" "$name" "icons/$icon"
			else
				printf "%s\n" "$name"
			fi
		done < "$DATA"
	fi
	exit 0
fi

choice="$1"

if [[ -n "${LINKS[$choice]}" ]]; then
	IFS='|' read -r url icon <<< "${LINKS[$choice]}"
	setsid -f xdg-open "$url" >/dev/null 2>&1
	exit 0
fi

if [[ -f "$DATA" ]]; then
	while IFS=$'\t' read -r name url icon; do
		if [[ "$name" == "$choice" ]]; then
			setsid -f xdg-open "$url" >/dev/null 2>&1
			exit 0
		fi
	done < "$DATA"
fi

query=$(printf "%s" "$choice" | sed 's/ /+/g')
setsid -f firefox "https://duckduckgo.com/?q=$query" >/dev/null 2>&1
exit 0