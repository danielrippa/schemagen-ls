
  do ->

    { parse-models } = dependency 'Models'
    { map-array-items: map } = dependency 'unsafe.Array'
    { lines-as-string, string-as-lines } = dependency 'unsafe.Text'
    { stdout, debug } = dependency 'os.shell.IO'
    { round-brackets: parens, circumfix } = dependency 'unsafe.Circumfix'

    { value-as-string } = dependency 'reflection.Value'

    pad = -> circumfix it, [ ' ' ]

    primary-key = (name) -> "#{ name } INTEGER PRIMARY KEY AUTOINCREMENT"
    foreign-key = ({ name, not-null }) -> "#{ name } INTEGER#{ if not-null then ' NOT NULL' else ''}"

    attribute = ({ name, type, not-null }) -> "#{ name } #{ type }#{ if not-null then ' NOT NULL' else '' }"

    unique-constraint = (fields) -> "UNIQUE #{ parens fields.join ', ' }"
    check-constraint = (expression) -> "CHECK #{ parens expression }"

    entity-prefix = ({ name }) -> "CREATE TABLE #{ name } ("
    entity-suffix = ');'

    entity-as-lines = (entity) ->

      sql = []

      return sql if entity is void

      if entity.pk isnt void => sql.push primary-key entity.pk

      for fk in entity.fk => sql.push foreign-key fk

      for attr in entity.attributes => sql.push attribute attr

      for unique in entity.unique => sql.push unique-constraint unique

      for check in entity.checks => sql.push check-constraint check

      lines = sql |> map _ , (-> "  #it") |> (* ',\n')

      [ entity-prefix entity ] ++ lines ++ [ entity-suffix ] |> lines-as-string

    sql = (filepath) ->

      filepath

        |> parse-models |> (.entities)
        |> map _ , entity-as-lines
        |> lines-as-string

        |> stdout

    {
      sql
    }