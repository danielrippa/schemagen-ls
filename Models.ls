
  do ->

    { create-error-context } = dependency 'prelude.error.Context'
    { trim-space } = dependency 'value.string.Whitespace'
    { string-as-lines, lines-as-string, string-as-words } = dependency 'value.string.Text'
    { try-read-textfile-lines } = dependency 'os.filesystem.TextFile'
    { array-size, drop-array-items: drop, drop-first-array-items: drop-first, append-items: append } = dependency 'value.Array'
    { string-interval-before } = dependency 'value.string.Segment'
    { file-exists } = dependency 'os.filesystem.File'
    { upper-case } = dependency 'value.string.Case'
    { stderr-lf } = dependency 'os.shell.IO'
    { exit } = dependency 'os.shell.Script'

    { create-error } = create-error-context 'Schemagen.Models'

    is-empty-line = (line) -> line |> trim-space |> -> it is ''

    model-error = (filepath, line, index, message) -> create-error do

      * "Error in model file '#filepath' at line ##{ line }."
        "Line: '#line'"
        message

      |> lines-as-string

    empty-file = -> if it is null then '' else it

    new-entity = (name) -> { name, pk: void, unique: [], fk: [], attributes: [], checks: [] }

    new-relationship = (source-entity, source-field, target-entity, target-field) -> { source-entity, source-field, target-entity, target-field }

    attribute-from-words = (words, line, index) ->

      type = switch words.0

        | 'T' => 'TEXT'
        | 'I' => 'INTEGER'
        | 'F' => 'REAL'
        | 'L' => 'BOOLEAN'
        | 'B' => 'BLOB'

        | 'TS' => 'DATETIME DEFAULT current_timestamp'

        else void

      return if type is void

      name = words.1

      not-null = (name.index-of '!') isnt -1

      if not-null => name = name.slice 0, -1

      { name, type, not-null }

    parse-model = (filepath) ->

      entity = void ; entities = [] ; relationships = []

      throw create-error "Model file '#filepath' not found" \
        unless file-exists filepath

      { value: model-lines, error } = try-read-textfile-lines filepath
      throw contextualized error unless error is void

      for model-line, index in model-lines

        line = trim-space model-line ; continue if line is ''

        words = string-as-words line ; words-count = array-size words ; keyword = upper-case words.0

        switch keyword

          | '*' =>

            throw model-error filepath, line, index, "Entities must specify a name (e.g '* EntityName')" \
              if words-count < 2

            entities.push entity  \
              if entity isnt void

            entity-name = words.1

            entity = new-entity entity-name

          | 'PK' =>

            throw model-error filepath, line, index, "Primary Keys must specify a name (e.g. 'PK PrimaryKeyName')" \
              if words-count < 2

            name = words.1

            throw model-error filepath, line, index, "Entity already has PK #{ entity.pk }" \
              if entity.pk isnt void

            entity.pk = name

          | 'FK' =>

            throw model-error filepath, line, index, "Foreign keys must specify both a Name and a Field reference (e.g. 'FK ForeignName EntityName.FieldName')" \
              if words-count < 3

            name = words.1
            field = words.2

            not-null = (name.index-of '!') isnt -1

            if not-null 
              name = name `string-interval-before` 1

            throw model-error filepath, line, index, "Foreign key Field references must be specified as EntityName.FieldName" \
              if (field.index-of '.') is -1

            [ foreign-entity-name, foreign-field-name ] = field.split '.'

            entity.fk.push { name, not-null }

            relationship = new-relationship entity.name, name, foreign-entity-name, foreign-field-name

            relationships.push relationship

          | 'U' =>

            throw model-error filepath, line, index, "Unique constraints must specify a list of fields (e.g. 'U FieldName1 FieldName2')" \
              if words-count < 1

            field-names = words `drop-first` 1

            entity.unique.push field-names

          | 'C' =>

            throw model-error filepath, line, index, "Check constraints must specify an expression (e.g. 'C (column_name > 0)')" \
              if words-count < 2

            expression = words `drop-first` 1 |> (* ' ')

            entity.checks.push expression

          | 'T', 'I', 'F', 'L', 'B', 'TS' =>

            throw model-error filepath, line, index, "Attributes must specify a Name (e.g. #that AttributeName)" \
              if words-count < 2

            attribute = attribute-from-words words

            throw model-error filepath, line, index, "Invalid attribute type '#{ words.0 }'" \
              if attribute is void

            entity.attributes.push attribute

          else

            throw model-error filepath, line, index, "Invalid statement '#line'"

      if entity isnt void => entities.push entity

      { entities, relationships }

    parse-models = (filepaths) ->

      entities = [] ; relationships = []

      for model-filepath in filepaths

        model = parse-model model-filepath

        try model = parse-model model-filepath
        catch error => (for k,v of error => stderr-lf "#k: #v") ; exit 1

        { entities: model-entities, relationships: model-relationships } = model

        entities `append` model-entities ; relationships `append` model-relationships

      { entities, relationships }

    {
      parse-models
    }