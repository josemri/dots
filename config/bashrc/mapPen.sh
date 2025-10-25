xinput disable "$(xinput list | grep "touch" | grep -o 'id=[0-9]\+' | cut -d= -f2)"
xinput map-to-output "$(xinput list | grep "Stylus stylus" | grep -o 'id=[0-9]\+' | cut -d= -f2)" DP-1
xinput map-to-output "$(xinput list | grep "Stylus eraser" | grep -o 'id=[0-9]\+' | cut -d= -f2)" DP-1
