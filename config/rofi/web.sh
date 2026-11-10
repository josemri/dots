#!/usr/bin/env bash

ROFI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINKS_FILE="$ROFI_DIR/web.links"

declare -A LINKS=()

usage() {
	printf 'uso: web.sh [--add <nombre> <url> | --remove <nombre> | <url, enlace o consulta>]\n' >&2
	printf 'en rofi: "+ <nombre> <url>" añade un enlace, "- <nombre>" lo elimina\n' >&2
}

# web.links: una entrada por linea, separada por tabuladores:
#   nombre <TAB> url <TAB> icono (fichero en icons/, puede estar vacio)
load_links() {
	local name url icon value

	[[ -f $LINKS_FILE ]] || return 0
	while IFS=$'\t' read -r name url icon || [[ -n $name ]]; do
		[[ -n "$name" && -n "$url" && "$name" != \#* ]] || continue
		value="$url"
		[[ -n "$icon" ]] && value="$value|icons/$icon"
		LINKS["$name"]="$value"
	done < "$LINKS_FILE"
}

add_link() {
	local name="$1"
	local url="$2"
	local domain iconfile icon=""

	if [[ -z "$name" || -z "$url" || "$name" == \#* || "$name" == *$'\t'* || "$name" == *$'\n'* || "$url" == *$'\t'* || "$url" == *$'\n'* || "$url" == *'|'* ]]; then
		return 1
	fi
	if [[ -n "${LINKS[$name]+x}" ]]; then
		return 1
	fi

	[[ "$url" =~ ^https?:// ]] || url="https://$url"
	domain=$(printf '%s' "$url" | sed -E 's|https?://([^/?#]+).*|\1|')
	iconfile=$(printf '%s' "$domain" | tr -cd '[:alnum:].-')

	if [[ -d "$ROFI_DIR/icons" && -x /usr/bin/curl ]]; then
		if curl -fsSL --max-time 10 "https://icons.duckduckgo.com/ip3/$domain.ico" -o "$ROFI_DIR/icons/$iconfile.ico"; then
			icon="$iconfile.ico"
		else
			rm -f -- "$ROFI_DIR/icons/$iconfile.ico"
			if curl -fsSL --max-time 10 "https://www.google.com/s2/favicons?domain=$domain&sz=128" -o "$ROFI_DIR/icons/$iconfile.png"; then
				icon="$iconfile.png"
			else
				rm -f -- "$ROFI_DIR/icons/$iconfile.png"
			fi
		fi
	fi

	printf '%s\t%s\t%s\n' "$name" "$url" "$icon" >> "$LINKS_FILE" || {
		return 1
	}

}

remove_link() {
	local name="$1"
	local icon=""

	if [[ -z "$name" || -z "${LINKS[$name]+x}" ]]; then
		return 1
	fi

	icon=$(awk -F'\t' -v n="$name" '$1 == n { print $3; exit }' "$LINKS_FILE")
	awk -F'\t' -v n="$name" '$1 != n' "$LINKS_FILE" > "$LINKS_FILE.tmp" && cat "$LINKS_FILE.tmp" > "$LINKS_FILE"
	rm -f -- "$LINKS_FILE.tmp"

	if [[ -n "$icon" ]] && ! awk -F'\t' -v i="$icon" '$3 == i { found = 1 } END { exit !found }' "$LINKS_FILE"; then
		rm -f -- "$ROFI_DIR/icons/$icon"
	fi
}

notify() {
	command -v notify-send >/dev/null && notify-send "web" "$1"
	printf '%s\n' "$1"
}

is_url() {
	local value="$1"
	local domain_pattern='^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}(:[0-9]+)?([/?#][^[:space:]]*)?$'
	local ip_pattern='^([0-9]{1,3}\.){3}[0-9]{1,3}(:[0-9]+)?([/?#][^[:space:]]*)?$'
	local localhost_pattern='^localhost(:[0-9]+)?([/?#][^[:space:]]*)?$'

	[[ "$value" =~ ^[Hh][Tt][Tt][Pp][Ss]?://[^[:space:]]+$ ]] && return 0
	[[ "$value" =~ ^$domain_pattern$ ]] && return 0
	[[ "$value" =~ ^$ip_pattern$ ]] && return 0
	[[ "$value" =~ ^$localhost_pattern$ ]]
}

open_url() {
	setsid -f xdg-open "$1" >/dev/null 2>&1
}

load_links

if [[ "${1-}" == --add ]]; then
	if [[ $# -ne 3 ]]; then
		usage
		exit 1
	fi
	add_link "$2" "$3"
	exit $?
fi

if [[ "${1-}" == --remove ]]; then
	if [[ $# -ne 2 ]]; then
		usage
		exit 1
	fi
	remove_link "$2"
	exit $?
fi

if [[ $# -eq 0 ]]; then
	for key in "${!LINKS[@]}"; do
		IFS='|' read -r url icon <<< "${LINKS[$key]}"
		if [[ -n "$icon" && -f "$ROFI_DIR/$icon" ]]; then
			printf "%s\0icon\x1f%s\n" "$key" "$icon"
		else
			printf "%s\n" "$key"
		fi
	done
	exit 0
fi

if [[ $# -ne 1 ]]; then
	usage
	exit 1
fi

choice="$1"
choice=${choice#"${choice%%[![:space:]]*}"}
choice=${choice%"${choice##*[![:space:]]}"}

[[ -n "$choice" ]] || exit 0

case "$choice" in
	+\ *)
		read -r name url <<< "${choice#+ }"
		notify "$(add_link "$name" "$url" 2>&1)"
		exit 0
		;;
	-\ *)
		read -r name _ <<< "${choice#- }"
		notify "$(remove_link "$name" 2>&1)"
		exit 0
		;;
esac

entry=""
for key in "${!LINKS[@]}"; do
	if [[ "$key" == "$choice" ]]; then
		entry="${LINKS[$key]}"
		break
	fi
done

if [[ -n "$entry" ]]; then
	IFS='|' read -r url icon <<< "$entry"
	open_url "$url"
	exit 0
fi

if is_url "$choice"; then
	if [[ "$choice" =~ ^[Hh][Tt][Tt][Pp][Ss]?:// ]]; then
		url="$choice"
	else
		url="https://$choice"
	fi
	open_url "$url"
	exit 0
fi

query=$(printf '%s' "$choice" | sed 's/ /+/g')
setsid -f librewolf "https://duckduckgo.com/?q=$query" >/dev/null 2>&1
exit 0
