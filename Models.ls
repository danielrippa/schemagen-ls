
  do ->

    { create-error-context } = dependency 'prelude.error.Context'
    { trim-space } = dependency 'value.string.Whitespace'
    { string-as-lines, string-as-words } = dependency 'value.string.Text'
    { read-textfile-lines } = dependency 'os.filesystem.TextFile'
    { array-size, drop-array-items: drop, drop-first-array-items: drop-first, append-items: append } = dependency 'value.Array'
    { string-interval-before } = dependency 'value.string.Segment'
    { file-exists } = dependency 'os.filesystem.File'
    { upper-case } = dependency 'value.string.Case'

    { create-error } = create-error-context 'Schemagen.Models'

    is-empty-line = (line) -> line |> trim-space |> -> it is ''

    model-error = (filepath, line, index, message) -> throw create-error do

      * "Error in model file '#filepath' at line ##{ line }."
        "Line: '#line'"
        message

      |> string-as-lines

    empty-file = -> if it is null then '' else it

    modelfile-found = (filepath) -> throw create-error "SchemaList file '#filepath' not found" unless file-exists filepath ; filepath

    textfile-lines = (filepath) -> filepath |> modelfile-found |> read-textfile-lines |> drop _ , is-empty-line

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

      if not-null => name = name `string-interval-before` 1

      { name, type, not-null }

    parse-model = (filepath) ->

      entity = void ; entities = [] ; relationships = []

      throw new Error "Model file '#filepath' not found" \
        unless file-exists filepath

      for line, index in textfile-lines filepath

        words = string-as-words trim-space line ; words-count = array-size words ; keyword = upper-case words.0

        switch keyword

          | '*' =>

            model-error filepath, line, index, "Entities must specify a name (e.g '* EntityName')" \
              if words-count < 2

            entities.push entity  \
              if entity isnt void

            entity-name = words.1

            entity = new-entity entity-name

          | 'PK' =>

            model-error filepath, line, index, "Primary Keys must specify a name (e.g. 'PK PrimaryKeyName')" \
              if words-count < 2

            name = words.1

            model-error filepath, line, index, "Entity already has PK #{ entity.pk }" \
              if entity.pk isnt void

            entity.pk = name

          | 'FK' =>

            model-error filepath, line, index, "Foreign keys must specify both a Name and a Field reference (e.g. 'FK ForeignName EntityName.FieldName')" \
              if words-count < 3

            name = words.1
            field = words.2

            not-null = (name.index-of '!') isnt -1

            if not-null 
              name = name `string-interval-before` 1

            model-error filepath, line, index, "Foreign key Field references must be specified as EntityName.FieldName" \
              if (field.index-of '.') is -1

            [ foreign-entity-name, foreign-field-name ] = field.split '.'

            entity.fk.push { name, not-null }

            relationship = new-relationship entity.name, name, foreign-entity-name, foreign-field-name

            relationships.push relationship

          | 'U' =>

            model-error filepath, line, index, "Unique constraints must specify a list of fields (e.g. 'U FieldName1 FieldName2')" \
              if words-count < 1

            field-names = words `drop-first` 1

            entity.unique.push field-names

          | 'C' =>

            model-error filepath, line, index, "Check constraints must specify an expression (e.g. 'C (column_name > 0)')" \
              if words-count < 2

            expression = words `drop-first` 1 |> (* ' ')

            entity.checks.push expression

          | 'T', 'I', 'F', 'L', 'B', 'TS' =>

            model-error filepath, line, index, "Attributes must specify a Name (e.g. #that AttributeName)" \
              if words-count < 2

            attribute = attribute-from-words words

            model-error filepath, line, index, "Invalid attribute type '#{ words.0 }'" \
              if attribute is void

            entity.attributes.push attribute

          else

            model-error filepath, line, index, "Invalid statement '#line'"

      if entity isnt void => entities.push entity

      { entities, relationships }

    parse-models = (filepaths) ->

      entities = [] ; relationships = []

      for model-filepath in filepaths

        { entities: model-entities, relationships: model-relationships } = parse-model model-filepath

        entities `append` model-entities ; relationships `append` model-relationships

      { entities, relationships }

    {
      parse-models
    }