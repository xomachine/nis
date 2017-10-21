# NIS
A Vis plugin that extends Nim language support.

<img width=50% src="https://pp.userapi.com/c837731/v837731894/60bd7/_qsEj38B5Mc.jpg" /><img width=50% src="https://pp.userapi.com/c840536/v840536607/7109/nDrnN95QV8g.jpg" /><img width=100% src="https://pp.userapi.com/c837731/v837731894/60bcf/wUvQyP7bfP4.jpg" />

## Features
* Autocompletion on Ctrl+Space (or **:nimsuggest** command, or after dot symbol)
* Calltips at the bottom of the editor when '(' is typed
* Search for the identifier under cursor definition on **:nimtodef** command
* The code under cursor documentation viewer on **:nimhelp** command
* Error highlighting on file save or on **:nimcheck** command
* Search/open file from the project via **:nimopen** command
* Project/File building support via **:nimble** command (**:nimble [target]** to perform project build or **:nimble c [options]** to build current file)

*Other features coming soon... or not so soon.*

## Requirements
* nimsuggest
* setsid (can be found in util-linux package on Archlinux, for example)

## Instalation
Clone this repository to your vis config directory (e.g. ~/.config/vis) and add to your visrc.lua following line
```lua
require('nis.init')
```
