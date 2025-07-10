
  do ->

    { parse-models } = dependency 'Models'
    { map-array-items: map } = dependency 'unsafe.Array'
    { lines-as-string } = dependency 'unsafe.Text'
    { stdout } = dependency 'os.shell.IO'

    { value-as-string } = dependency 'reflection.Value'

    indent = (string, n) -> "#{ ' ' * n }#string"

    entity-prefix = ({ name }) -> "entity #name {"

    entity-suffix = '}'

    entity-as-lines = (entity) ->

      lines = [] ; lines.push entity-prefix entity

      if entity.pk isnt void => lines.push indent '* #{ entity.pk }', 2

      lines.push '--'

      for fk in entity.fk => lines.push indent '* #fk', 2

      lines.push '--'

      for attribute in entity.attributes

        lines.push indent "#{ if attribute.not-null then '*' else '' }#{ attribute.name }", 2

      lines.push entity-suffix

      lines |> lines-as-string

    as-puml = (lines) -> <[ @startuml ]> ++ lines ++ <[ @enduml ]>

    puml = (filepath) ->

      filepath

        |> parse-models
        |> (.entities)
        |> map _ , entity-as-lines |> as-puml
        |> lines-as-string

        |> stdout

    {
      puml
    }