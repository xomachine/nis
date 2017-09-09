# nis
The Vis plugin that extends Nim language support.

<img width=50% src="https://pp.userapi.com/c837731/v837731894/60bcf/wUvQyP7bfP4.jpg" /><img width=50% src="https://pp.userapi.com/c837731/v837731894/60bd7/_qsEj38B5Mc.jpg" />

## Features
* Autocompletion on Ctrl+Space (or **:suggest** command, or after dot symbol)
* Calltips at the bottom of the editor then '(' is typed
* Search for identifier under cursor definition on **:nimtodef** command
* Code under cursor documentation viewer on **:nimhelp** command

*Other features coming soon... or not so soon.*

## Requirements
* nimsuggest
* bash
* setsid (can be found in util-linux package on Archlinux, for example)

## Instalation
Clone this repository to your vis config directory (e.g. ~/.config/vis) and add to your visrc.lua following line
```lua
require('nis.init')
```
