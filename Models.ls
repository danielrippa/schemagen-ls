
  do ->

    { read-textfile } = dependency 'os.filesystem.TextFile'
    { string-as-lines } = dependency 'unsafe.Text'
    { drop-array-items: drop, array-concat: concat } = dependency 'unsafe.Array'
    { trimmed-string } = dependency 'unsafe.Whitespace'
    { upper-case } = dependency 'unsafe.StringCase'
    { array-size, array-concat } = dependency 'unsafe.Array'
    { drop-last-string-chars, string-as-words } = dependency 'unsafe.String'
    { file-exists } = dependency 'os.filesystem.File'
    { result-or-error } = dependency 'flow.Conditional'

    { debug } = dependency 'os.shell.IO'
    { value-as-string } = dependency 'reflection.Value'

    is-empty-line = (line) -> line |> trimmed-string |> -> it is ''

    model-error = (filepath, line, index, message) -> throw new Error do

      * "Error in model file '#filepath' at line ##{ line }."
        "Line: '#line'"
        message

      |> string-as-lines

    empty-file = -> if it is null then '' else it

    modelfile-found = (filepath) -> throw new Error "SchemaList file '#filepath' not found" unless file-exists filepath ; filepath

    textfile-lines = (filepath) -> filepath |> modelfile-found |> read-textfile |> string-as-lines |> drop _ , is-empty-line

    new-entity = (name) -> { name, pk: void, unique: [], fk: [], attributes: [] }

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

      if not-null

        name = name `drop-last-string-chars` 1

      { name, type, not-null }

    parse-model = (filepath) ->

      entity = void ; entities = [] ; relationships = []

      throw new Error "Model file '#filepath' not found" \
        unless file-exists filepath

      for line, index in textfile-lines filepath

        words = string-as-words trimmed-string line ; words-count = array-size words ; keyword = upper-case words.0

        switch keyword

          | '*' =>

            model-error filepath, line, index, "Entities must specify a name (e.g '* EntityName')" \
              if words-count < 2

            entities.push entity  \
              if entity isnt void

            entity = new-entity words.1

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

            model-error filepath, line, index, "Foreign key Field references must be specified as EntityName.FieldName" \
              if (field.index-of '.') is -1

            [ foreign-entity-name, foreign-field-name ] = field.split '.'

            entity.fk.push name

            relationships.push "#{ entity.name }::#{ name } -- #foreign-entity-name::#foreign-field-name"

          | 'U' =>

            model-error filepath, line, index, "Unique constraints must specify a list of fields (e.g. 'U FieldName1 FieldName2')" \
              if words-count < 1

            field-names = words `drop-first` 1

            entity.unique.push field-names

          | 'T', 'I', 'F', 'L', 'B', 'TS' =>

            model-error filepath, line, index, "Attributes must specify a Name (e.g. #that AttributeName)" \
              if words-count < 2

            attribute = attribute-from-words words

            model-error filepath, line, index, "Invalid attribute type '#{ words.0 }'" \
              if attribute is void

            entity.attributes.push attribute

          else

            model-error filepath, line, index, "Invalid statement '#line'"

      if entity isnt void
        entities.push entity

      { entities, relationships }

    get-filepaths = (filepath) -> texfile-lines filepath

    parse-models = (filepath) ->

      entities = [] ; relationships = []

      for model-filepath in textfile-lines filepath

        { entities: model-entities, relationships: model-relationships } = parse-model model-filepath

        concat entities, model-entities
        concat relationships, model-relationships

      { entities, relationships }

    {
      parse-models
    }