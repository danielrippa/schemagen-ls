
  do ->

    { parse-models } = dependency 'Models'
    { map-array-items: map, array-size } = dependency 'unsafe.Array'
    { lines-as-string } = dependency 'unsafe.Text'
    { stdout } = dependency 'os.shell.IO'
    { indent-string: indent } = dependency 'unsafe.String'

    { value-as-string } = dependency 'reflection.Value'

    entity-prefix = ({ name }) -> "entity #name {"

    entity-suffix = '}'

    entity-as-lines = (entity) ->

      lines = [] ; lines.push entity-prefix entity

      if entity.pk isnt void => lines.push indent "* #{ entity.pk }"

      if (array-size entity.fk) isnt 0

        lines.push '--'

        for fk in entity.fk => lines.push indent "* #fk"

      if (array-size entity.attributes) isnt 0

        lines.push '--'

        for attribute in entity.attributes

          lines.push indent "#{ if attribute.not-null then '*' else '' }#{ attribute.name }"

      if (array-size entity.checks) isnt 0

        lines.push '--'

        for expression in entity.checks

          lines.push indent "constraint #expression"

      lines.push entity-suffix

      lines |> lines-as-string

    relationship-as-lines = ({ source-entity, source-field, target-entity, target-field })->

      [ "#source-entity::#source-field -- #target-entity::#target-field" ]

    as-puml = (lines) -> <[ @startuml ]> ++ lines ++ <[ @enduml ]>

    entities-as-lines = (entities) -> map entities, entity-as-lines

    relationships-as-lines = (relationships) -> map relationships, relationship-as-lines

    models-as-lines = ({ entities, relationships }) ->

      (entities-as-lines entities) ++ (relationships-as-lines relationships)

    puml = (filepath) ->

      filepath

        |> parse-models
        |> models-as-lines |> as-puml
        |> lines-as-string

        |> stdout

    {
      puml
    }