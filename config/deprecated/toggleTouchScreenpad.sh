# bindsym Shift+XF86TouchpadToggle exec --no-startup-id ./.config/toggleTouchScreenpad.sh

ID=$(xinput list --id-only "ELAN9009:00 04F3:2C58")

if [ "$(xinput list-props $ID | grep "Device Enabled" | awk '{print $4}')" -eq 1 ]; then
        xinput disable $ID;
else
        xinput enable $ID;
fi;
