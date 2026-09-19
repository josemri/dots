#!/usr/bin/env bash

ROFI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONDIR="$ROFI_DIR/icons"
DATA="$ROFI_DIR/web_custom"

[[ $# -lt 2 ]] && { echo "uso: add_web.sh <nombre> <url>" >&2; exit 1; }

name="$1"
url="$2"

[[ "$url" =~ ^https?:// ]] || url="https://$url"

domain=$(printf "%s" "$url" | sed -E 's|https?://([^/?#]+).*|\1|')
iconfile=$(printf "%s" "$domain" | tr -cd '[:alnum:].-')

icon=""
if [[ -x /usr/bin/curl ]]; then
	if curl -fsSL --max-time 10 "https://icons.duckduckgo.com/ip3/$domain.ico" -o "$ICONDIR/$iconfile.ico"; then
		icon="$iconfile.ico"
	elif curl -fsSL --max-time 10 "https://www.google.com/s2/favicons?domain=$domain&sz=128" -o "$ICONDIR/$iconfile.png"; then
		icon="$iconfile.png"
	fi
fi

if [[ -f "$DATA" ]]; then
	grep -vF "$name"$'\t' "$DATA" > "$DATA.tmp"
	mv -f "$DATA.tmp" "$DATA"
fi
printf "%s\t%s\t%s\n" "$name" "$url" "$icon" >> "$DATA"
echo "añadida: $name -> $url"
exit 0