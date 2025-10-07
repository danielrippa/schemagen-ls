
  do ->

    { stdout-lines } = dependency 'os.shell.IO'

    help = ->

      * "SCHEMA SYNTAX"
        ''
        "* EntityName"
        ''
        "  PK KeyName"
        "  FK KeyName[!] TargetEntity.TargetColumn (1)"
        ''
        "  ColumnType ColumnName[1] (1)(2)"
        ''
        "  U Column1 Column2 (3)"
        "  C Expression (4)"
        ''
        "WHERE"
        "(1) '!' for NOT NULL"
        '(2) ColumnType is one from ColumnTypes table'
        '(3) U is for Unique Constraint on listed columns'
        '(4) C is for Check Constraint on Expression'
        ''
        "COLUMN TYPES"
        ''
        "T Text"
        "I Integer"
        "F Real"
        "L Boolean"
        "B Blob"
        "TS DATETIME DEFAULT current_timestamp"

      |> stdout-lines

    {
      help
    }