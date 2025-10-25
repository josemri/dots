#!/bin/bash
cpu_temp=$(($(cat "/sys/class/thermal/thermal_zone0/temp") / 1000))
echo "<span background='#ffadad' font_weight='bold'>  </span><span background='#ffadad' font_weight='bold'>${cpu_temp}󰔄 </span>"

