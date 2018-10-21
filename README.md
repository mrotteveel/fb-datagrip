# fb-datagrip

Information for adding Firebird support to DataGrip / IntelliJ

DataGrip information needs are listed on https://www.jetbrains.com/datagrip/new_dbms/

See also [DBE-3650 Firebird Dialect Support](https://youtrack.jetbrains.com/issue/DBE-3650).

## Version

Information based on Firebird 2.5 and 3.0.

## Important limitations

Licensing requirements for documentation under discussion with JetBrains. 
Until that is resolved, **do not** copy information from other Firebird documentation.

## Function documentation

The function documentation is defined in `src/functions/` and converted to HTML fragments using asciidoctor.
Use `gradlew` to rebuild the HTML fragments in `functions/`

