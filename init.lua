
local events = vis.events

local function check_nimsuggest()
  local success, ecode, sig = os.execute('nimsuggest -v &> /dev/null')
  return success
end

if check_nimsuggest() then
  require('nis.session_manager')
  require('nis.dispatcher')
  require('nis.project')
  events.subscribe("NISGOTANSWER", dispatch)
  events.subscribe(events.FILE_OPEN, on_open)
  events.subscribe(events.FILE_SAVE_POST, check_it)
  events.subscribe(events.QUIT, stop_all)
  events.subscribe(events.WIN_HIGHLIGHT, cycle_all)
  events.subscribe(events.WIN_CLOSE,
                   function(w) -- Removing all windows attached to this one
                     return (w.notifier and w.notifier:destroy()) or
                            (w.errormessage and w.errormessage:destroy())
                   end)
  events.subscribe(events.FILE_CLOSE, on_close)
  events.subscribe(events.INPUT, dispatch_input)

  vis:command_register("nimsuggest", suggest_key)
  vis:command_register("nimtodef", goto_def)
  vis:command_register("nimhelp", get_help)
  vis:command_register("nimcheck", check_it)
  vis:command_register("nimopen", openInProject)

  vis:map(vis.modes.INSERT, "<C- >", suggest_key,
          "Suggest the Nim symbol using nimsuggest.")
end
