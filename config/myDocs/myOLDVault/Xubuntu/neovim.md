La idea es ir aprendiendo a utilizar nvim ya que por lo que he estado viendo parece ser muchisimo mejor que cualquiero otro editor cli, basicamente por el init.lua y los pliguns que desarrolla la comunidad.

Lo primero que quiero hacer antes de empezar es cambiar el comando que utiliza neovim para editar ya que aun que sean cuatro letras me gustaria tener algo que sea de solo una letra como 'n' de neovim o 'e' de edit. Esto se consigue añadiendo un alias a [[Xubuntu/bashrc]] bastante directo:
```bash
alias n='nvim';
```

## Kickstart.nvim

[Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) es una init.lua hecho por uno de los programadores de nvim, basicamente es un copia y pega y te lo deja todo hecho. Lo unico que he tenido que hacer es intalar npm ```sudo apt install npm``` para poder tener basicamente un IDE completo, lo unico que me falta es ejecutar archivos, aun que para lo que lo estoy usando de momento siento que no lo necesito.  A parte de eso para habilitar la ayuda de otros lenguajes mas que el que viene por defecto con esta config que es lua, tienes que entrar en :Mason y con la interfaz grafica instalarlos. Yo tengo puesto bash, clangd, html, lua, python, rust y stylua. La mayoria no creo que llegue a utilizarlos pero los he dejado por si me da por ahi. Tambien he cambiado el tema que viene por defecto con el paquete([tokyonight.nvim](https://github.com/folke/tokyonight.nvim)) por el tema [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim). en modo oscuro. Fuera de eso no he tocado nada mas. Probablemente con el tiempo acabe cambiandome a la versión [modular](https://github.com/dam9000/kickstart-modular.nvim) ya que supongo que es mejor para añadir o quitar pluggins, pero de momento estoy contento con lo que tengo.


### Aprende nvim

Creo que me ha resultado mucho mas util simplemente utilizar el editor antes que aprenderme esto de memoria ya que la gran mayoria de cosas no las he usado ni creo que las use.

Leader key: atajos custom
visual mode: seleccionar texto
	visual block mode: seleccionar texto en bloque
normal mode: commands
isert mode: editar 

h
j
k
l

xh : donde x es un numero, va a saltar x caracteres a la izquierda
xj : donde x es un numero, va a saltar x lineas hacia arriba
xk : donde x es un numero, va a saltar x lineas hacia abajo
xl : donde x es un numero, va a saltar x caracteres a la derecha

w : para saltar a princpio de la siguiente palabra
b : para saltar al principio de la palabra anterior
e : para saltar al final de la palabra seleccionada

$ : para saltar al final de la linea
0 : para saltar al principio de la fila

^ : salta al primer caracter que no esta vacío
f + x : donde x es la siguiente instancia de la letra a la que queremos ir
F + x : donde x es la anterior instancia de la letra a la que queremos ir

( :saltar a la linea anterior, pero con frases o algo asi
) :saltar a la siguitente linea, igual que la ( pero al contrario

{ :saltar al parrafo de arriba
} :saltar al parrafo de abajo

CTRL + d : saltar a la mitad de la pagina anterior
CTRL + u : saltar a la mitad de la pagina posterior

CTRL + f : saltar a principio de pagina
CTRL + b: saltar al final de la pagina

gg : principio de pagina
G : final de pagina


INSERT MODE

dependiendo de la posición del curson y de como entres en el modo inserción va a escribir en un sitio u otro

i : meter texto antes del cursor
a : meter texto despues del cursor
I : meter texto al principio de la linea
A : meter texto al final de la linea

o : meter texto en una nueva linea debajo de la actual
O : meter texto en una nueva linea encima de la actual

c : para cambiar la palabra
s : para cambiar un caracter y entrar en modo edicion

y : COPIAR
p : PEGAR
yy :copiar la linea entera (al pegar lo va a interpretar como \n + contenido)

u : para deshacer cambios
CTRL r : rehacer cambios

d i w : borrar la palabra seleccionada
d i s : borrar la frase seleccionada
d i p : borrar el paragrafo seleccionado
dd : borrar una linea entera
d t x : donde x es el caracter en el que quieres terminar de borrar

. : para repetir la ultima accion

/ x : para buscar terminos, va a asignar el primer valor que sigue al cursor
n : siguiente valor
N : valor anterior
. * : busca la palabra que este debajo del cursor
. # : buscar la palabra que este encima del cursor

Para marcar una posición puedes hacer un bookmark
m + x donde x es la letra que sirve como identificador para el bookmark
` + x donde x es el bookmark ya creado, te lleva a ese punto
` + . para ir al ultimo punto editado


zM : Para plegar todas las zonas de codigo 
zR : Para desplegar todas las zonas de codigo
zc : para plegar una zona de codigo en concreto
zo : desplegar esa zona de codigo en concreto

