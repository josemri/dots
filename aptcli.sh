#!/bin/bash

# Buscar paquetes usando apt-cache y fzf
selected_package=$(apt-cache search . | fzf --preview "apt show {1} | grep -E 'Package|Version|Description|Homepage|Section|Maintainer|Installed-Size|Pre-Depends|Depends'" --preview-window=right:50%:wrap)

# Extraer el nombre del paquete seleccionado (la primera columna)
package_name=$(echo "$selected_package" | awk '{print $1}')

# Comprobar si se seleccionó un paquete
if [ -z "$package_name" ]; then
    echo "No se seleccionó ningún paquete."
    exit 1
fi

# Confirmar la instalación del paquete
echo "Instalando $package_name..."
sudo apt install "$package_name"

