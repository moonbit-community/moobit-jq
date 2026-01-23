///|
/// Parser error types
pub(all) suberror ParseError {
  UnexpectedToken(String, String) // (found, expected) - using String to avoid ToJson requirement
  UnexpectedEnd(String) // (expected)
  InvalidSyntax(String)
  InvalidExpression(String)
} derive(Eq, Debug, Show)
