
  { create-error-context } = dependency 'prelude.error.Context'
  { script-arguments: argv, script-arguments-count: argc, exit, script-usage } = dependency 'os.shell.Script'
  { stdout-lines, stderr-lines } = dependency 'os.shell.IO'
  { sql } = dependency 'Sql'
  { puml } = dependency 'Puml'

  { value-as-string } = dependency 'prelude.reflection.Value'

  usage = -> script-usage [ 'sql|puml schema-filepath...' ]

  #

  if argc < 2 => stdout-lines usage! ; exit 1

  [ command, ...filepaths ] = argv

  switch command

    | 'sql' => sql filepaths
    | 'puml' => puml filepaths

    else stderr-lines usage! ++ [ '', "Unknown command '#command'." ] ; exit 2

