require('nis.session_manager')
local events = vis.events

events.subscribe(events.FILE_OPEN, on_open)
events.subscribe(events.QUIT, stop_all)
events.subscribe(events.WIN_HIGHLIGHT, cycle_all)
events.subscribe(events.FILE_CLOSE, on_close)
