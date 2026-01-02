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
  inspect(@parser.lex("-"), content="[TMinus, TEof]")
}

///|
test "coverage: string escape sequences" {
  let query : Array[String] = [
    "\"\\n\"", "\"\\r\"", "\"\\t\"", "\"\\b\"", "\"\\/\"", "\"\\\"\"", "\"\\\\\"",
  ]
  let expected : Array[String] = ["\n", "\r", "\t", "\b", "/", "\"", "\\"]
  for i = 0; i < query.length(); i = i + 1 {
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
      inspect(parts.length(), content="3")
      inspect(parts[0].0, content="x ")
      inspect(parts[1].1.unwrap(), content="(1 + (2)) | \"a\\\"b\"")
      inspect(parts[2].0, content=" y")
    }
    _ => inspect(false, content="expected TStringInterpolation")
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
