///|
/// Lexing basic tokens
test "lex: empty input" {
  let tokens = @parser.lex("")
  debug_inspect(tokens, content="[TEof]")
}

///|
test "lex: dot operator" {
  let tokens = @parser.lex(".")
  debug_inspect(tokens, content="[TDot, TEof]")
}

///|
test "lex: field access" {
  let tokens = @parser.lex(".foo")
  debug_inspect(tokens, content="[TDot, TIdentifier(\"foo\"), TEof]")
}

///|
test "lex: array index" {
  let tokens = @parser.lex(".[0]")
  debug_inspect(
    tokens,
    content="[TDot, TLBracket, TNumber(0), TRBracket, TEof]",
  )
}

///|
test "lex: array iterator" {
  let tokens = @parser.lex(".[]")
  debug_inspect(tokens, content="[TDot, TLBracket, TRBracket, TEof]")
}

///|
test "lex: numbers" {
  let tokens = @parser.lex("123 45.67 -89 -0.5")
  debug_inspect(
    tokens,
    content="[TNumber(123), TNumber(45.67), TNumber(-89), TNumber(-0.5), TEof]",
  )
}

///|
test "lex: string literals" {
  let tokens = @parser.lex("\"hello\" \"world\"")
  debug_inspect(
    tokens,
    content="[TString(\"hello\"), TString(\"world\"), TEof]",
  )
}

///|
test "lex: string escapes" {
  let tokens = @parser.lex("\"hello\\nworld\" \"tab\\there\" \"quote\\\"test\"")
  debug_inspect(
    tokens,
    content="[TString(\"hello\\nworld\"), TString(\"tab\\there\"), TString(\"quote\\\"test\"), TEof]",
  )
}

///|
test "lex: boolean and null literals" {
  let tokens = @parser.lex("true false null")
  debug_inspect(tokens, content="[TTrue, TFalse, TNull, TEof]")
}

///|
test "lex: keywords" {
  let tokens = @parser.lex("if then else end and or not")
  debug_inspect(
    tokens,
    content="[TIf, TThen, TElse, TEnd, TAnd, TOr, TNot, TEof]",
  )
}

///|
test "lex: variable" {
  let tokens = @parser.lex("$foo $bar123")
  debug_inspect(
    tokens,
    content="[TVariable(\"foo\"), TVariable(\"bar123\"), TEof]",
  )
}
