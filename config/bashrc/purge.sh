#!/bin/bash

#teniendo en cuenta que si haces dpkg --list | awk '$1=="rc"{print $2}' muestra los paquetes que no se han desintalado del todo porque quedan algun archivo de configuracion  este comando limpia completamente todo los archivos de config que quedan por desinstalar y limpia la cache

sudo apt clean
sudo apt autoremove
sudo apt autoclean
dpkg --list | awk '$1=="rc"{print $2}' | xargs sudo apt purge --auto-remove -y
