Jaybird 3.0.x: https://www.firebirdsql.org/en/jdbc-driver/

Jaybird comes in Java specific variants: jdk17 for Java 7, and jdk18 for Java 8 and higher. It is probably best to use jdk18

Maven coordinates:

- Java 7: `org.firebirdsql.jdbc:jaybird-jdk17:3.0.5`
- Java 8 and higher: `org.firebirdsql.jdbc:jaybird-jdk18:3.0.5`

Alternatively, use the `org.firebirdsql.jdbc:jaybird:3.0.5` coordinates (redirects to the jaybird-jdk18 coordinates).
