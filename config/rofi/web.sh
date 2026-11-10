#!/usr/bin/env bash

ROFI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINKS_FILE="$ROFI_DIR/web.links"

declare -A LINKS=()

usage() {
	printf 'uso: web.sh [--add <nombre> <url> | <url, enlace o consulta>]\n' >&2
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
		printf 'nombre o url no válidos: no pueden contener tabuladores, saltos de línea ni | en la url, y el nombre no puede empezar por #\n' >&2
		return 1
	fi
	if [[ -n "${LINKS[$name]+x}" ]]; then
		printf 'ya existe un enlace llamado %s\n' "$name" >&2
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
		printf 'no se pudo actualizar %s\n' "$LINKS_FILE" >&2
		return 1
	}

	printf 'añadida: %s -> %s\n' "$name" "$url"
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
