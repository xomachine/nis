require('nis.session_manager')
require('nis.dispatcher')
local events = vis.events

events.subscribe("NISGOTANSWER", dispatch)
events.subscribe(events.FILE_OPEN, on_open)
events.subscribe(events.QUIT, stop_all)
events.subscribe(events.WIN_HIGHLIGHT, cycle_all)
events.subscribe(events.FILE_CLOSE, on_close)

vis:command_register("suggest", suggest_key)
vis:command_register("nimhelp", get_help)
