
  { execute-command } = dependency 'os.shell.ScriptCommands'
  { argv } = dependency 'os.shell.ScriptArgs'
  { sql } = dependency 'Sql'
  { puml } = dependency 'Puml'

  execute-command { sql, puml }, argv

