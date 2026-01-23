///|
/// Lexer error type
pub suberror LexError {
  UnexpectedChar(Int, Char)
  UnterminatedString(Int)
  InvalidNumber(Int, String)
  InvalidEscape(Int, Char)
} derive(Eq, Debug, Show)
