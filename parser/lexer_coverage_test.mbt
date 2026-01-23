///|
fn lex_err(query : String) -> Bool {
  try @parser.lex(query) catch {
    _ => true
  } noraise {
    _ => false
  }
}

///|
test "coverage: peek at end of input" {
  // Triggers lexer.peek() at end for '-' number lookahead.
  debug_inspect(@parser.lex("-"), content="[TMinus, TEof]")
}

///|
test "coverage: string escape sequences" {
  let query : Array[String] = [
    "\"\\n\"", "\"\\r\"", "\"\\t\"", "\"\\b\"", "\"\\/\"", "\"\\\"\"", "\"\\\\\"",
  ]
  let expected : Array[String] = ["\n", "\r", "\t", "\b", "/", "\"", "\\"]
  for i in 0..<query.length() {
    let tokens = @parser.lex(query[i])
    match tokens[0] {
      TString(s) => assert_true(s == expected[i])
      _ => assert_true(false)
    }
  }
}

///|
test "coverage: interpolation lexer handles nested parens and strings" {
  // Includes nested parentheses and a nested string with an escaped quote.
  let query : String =
    #|"x \((1 + (2)) | "a\"b") y"
  let tokens = @parser.lex(query)
  match tokens[0] {
    TStringInterpolation(parts) => {
      debug_inspect(parts.length(), content="3")
      debug_inspect(parts[0].0, content="x ")
      debug_inspect(parts[1].1.unwrap(), content="(1 + (2)) | \"a\\\"b\"")
      debug_inspect(parts[2].0, content=" y")
    }
    _ => debug_inspect(false, content="expected TStringInterpolation")
  }
}

///|
test "coverage: lex errors for unexpected characters" {
  assert_true(lex_err("!"))
  assert_true(lex_err("~"))
}

///|
test "coverage: unterminated strings" {
  assert_true(lex_err("\"abc"))
  assert_true(lex_err("\"\\("))
  assert_true(lex_err("\"\\(\""))
}

///|
test "coverage: unterminated escape at end" {
  let sb = StringBuilder::new()
  sb..write_char('"')..write_char('\\')
  assert_true(lex_err(sb.to_string()))
}
