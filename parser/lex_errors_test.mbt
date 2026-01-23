///|
/// Lexing error handling
test "lex: error - unterminated string" {
  let result = try? @parser.lex("\"hello")
  match result {
    Err(@parser.LexError::UnterminatedString(_)) =>
      debug_inspect(true, content="true")
    _ => debug_inspect(false, content="should be UnterminatedString error")
  }
}

///|
test "lex: error - invalid escape" {
  let result = try? @parser.lex("\"hello\\x\"")
  match result {
    Err(@parser.LexError::InvalidEscape(_, _)) =>
      debug_inspect(true, content="true")
    _ => debug_inspect(false, content="should be InvalidEscape error")
  }
}

///|
test "lex: error - unexpected character" {
  let result = try? @parser.lex("@")
  match result {
    Err(@parser.LexError::UnexpectedChar(_, _)) =>
      debug_inspect(true, content="true")
    _ => debug_inspect(false, content="false")
  }
}
