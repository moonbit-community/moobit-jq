///|
test "lex: empty input" {
  let tokens = lex("")
  inspect(tokens, content="[TEof]")
}

///|
test "lex: dot operator" {
  let tokens = lex(".")
  inspect(tokens, content="[TDot, TEof]")
}

///|
test "lex: field access" {
  let tokens = lex(".foo")
  inspect(tokens, content="[TDot, TIdentifier(\"foo\"), TEof]")
}

///|
test "lex: pipe operator" {
  let tokens = lex(".foo | .bar")
  inspect(
    tokens,
    content="[TDot, TIdentifier(\"foo\"), TPipe, TDot, TIdentifier(\"bar\"), TEof]",
  )
}

///|
test "lex: array index" {
  let tokens = lex(".[0]")
  inspect(tokens, content="[TDot, TLBracket, TNumber(0), TRBracket, TEof]")
}

///|
test "lex: array iterator" {
  let tokens = lex(".[]")
  inspect(tokens, content="[TDot, TLBracket, TRBracket, TEof]")
}

///|
test "lex: numbers" {
  let tokens = lex("123 45.67 -89 -0.5")
  inspect(
    tokens,
    content="[TNumber(123), TNumber(45.67), TNumber(-89), TNumber(-0.5), TEof]",
  )
}

///|
test "lex: string literals" {
  let tokens = lex("\"hello\" \"world\"")
  inspect(tokens, content="[TString(\"hello\"), TString(\"world\"), TEof]")
}

///|
test "lex: string escapes" {
  let tokens = lex("\"hello\\nworld\" \"tab\\there\" \"quote\\\"test\"")
  inspect(
    tokens,
    content="[TString(\"hello\\nworld\"), TString(\"tab\\there\"), TString(\"quote\\\"test\"), TEof]",
  )
}

///|
test "lex: boolean and null literals" {
  let tokens = lex("true false null")
  inspect(tokens, content="[TTrue, TFalse, TNull, TEof]")
}

///|
test "lex: keywords" {
  let tokens = lex("if then else end and or not")
  inspect(tokens, content="[TIf, TThen, TElse, TEnd, TAnd, TOr, TNot, TEof]")
}

///|
test "lex: arithmetic operators" {
  let tokens = lex("+ - * / %")
  inspect(tokens, content="[TPlus, TMinus, TStar, TSlash, TPercent, TEof]")
}

///|
test "lex: comparison operators" {
  let tokens = lex("== != < <= > >=")
  inspect(tokens, content="[TEq, TNeq, TLt, TLe, TGt, TGe, TEof]")
}

///|
test "lex: comma and semicolon" {
  let tokens = lex(", ;")
  inspect(tokens, content="[TComma, TSemicolon, TEof]")
}

///|
test "lex: brackets and braces" {
  let tokens = lex("( ) [ ] { }")
  inspect(
    tokens,
    content="[TLParen, TRParen, TLBracket, TRBracket, TLBrace, TRBrace, TEof]",
  )
}

///|
test "lex: variable" {
  let tokens = lex("$foo $bar123")
  inspect(tokens, content="[TVariable(\"foo\"), TVariable(\"bar123\"), TEof]")
}

///|
test "lex: assignment operators" {
  let tokens = lex("= |= //")
  inspect(tokens, content="[TAssign, TUpdate, TAlternative, TEof]")
}

///|
test "lex: dot dot" {
  let tokens = lex("..")
  inspect(tokens, content="[TDotDot, TEof]")
}

///|
test "lex: comment" {
  let tokens = lex("# comment\n.foo")
  inspect(tokens, content="[TDot, TIdentifier(\"foo\"), TEof]")
}

///|
test "lex: complex expression" {
  let tokens = lex(".foo | map(.bar) | select(. > 10)")
  inspect(
    tokens,
    content=(
      #|[TDot, TIdentifier("foo"), TPipe, TIdentifier("map"), TLParen, TDot, TIdentifier("bar"), TRParen, TPipe, TIdentifier("select"), TLParen, TDot, TGt, TNumber(10), TRParen, TEof]
    ),
  )
}

///|
test "lex: object construction" {
  let tokens = lex("{foo: .bar, baz: 42}")
  inspect(
    tokens,
    content=(
      #|[TLBrace, TIdentifier("foo"), TColon, TDot, TIdentifier("bar"), TComma, TIdentifier("baz"), TColon, TNumber(42), TRBrace, TEof]
    ),
  )
}

///|
test "lex: array construction" {
  let tokens = lex("[1, 2, 3]")
  inspect(
    tokens,
    content="[TLBracket, TNumber(1), TComma, TNumber(2), TComma, TNumber(3), TRBracket, TEof]",
  )
}

///|
test "lex: if-then-else" {
  let tokens = lex("if .x > 0 then .x else 0 end")
  inspect(
    tokens,
    content=(
      #|[TIf, TDot, TIdentifier("x"), TGt, TNumber(0), TThen, TDot, TIdentifier("x"), TElse, TNumber(0), TEnd, TEof]
    ),
  )
}

///|
test "lex: as expression" {
  let tokens = lex(". as $x | $x + 1")
  inspect(
    tokens,
    content=(
      #|[TDot, TAs, TVariable("x"), TPipe, TVariable("x"), TPlus, TNumber(1), TEof]
    ),
  )
}

///|
test "lex: reduce expression" {
  let tokens = lex("reduce .[] as $x (0; . + $x)")
  inspect(
    tokens,
    content=(
      #|[TReduce, TDot, TLBracket, TRBracket, TAs, TVariable("x"), TLParen, TNumber(0), TSemicolon, TDot, TPlus, TVariable("x"), TRParen, TEof]
    ),
  )
}

///|
test "lex: try-catch" {
  let tokens = lex("try .foo catch \"error\"")
  inspect(
    tokens,
    content="[TTry, TDot, TIdentifier(\"foo\"), TCatch, TString(\"error\"), TEof]",
  )
}

///|
test "lex: optional operator" {
  let tokens = lex(".foo?")
  inspect(tokens, content="[TDot, TIdentifier(\"foo\"), TQuestion, TEof]")
}

///|
test "lex: whitespace handling" {
  let tokens = lex("  .foo  \n  |  \t  .bar  ")
  inspect(
    tokens,
    content="[TDot, TIdentifier(\"foo\"), TPipe, TDot, TIdentifier(\"bar\"), TEof]",
  )
}

///|
test "lex: error - unterminated string" {
  let result = try? lex("\"hello")
  match result {
    Err(LexError::UnterminatedString(_)) => inspect(true, content="true")
    _ => inspect(false, content="should be UnterminatedString error")
  }
}

///|
test "lex: error - invalid escape" {
  let result = try? lex("\"hello\\x\"")
  match result {
    Err(LexError::InvalidEscape(_, _)) => inspect(true, content="true")
    _ => inspect(false, content="should be InvalidEscape error")
  }
}

///|
test "lex: error - unexpected character" {
  let result = try? lex("@")
  match result {
    Err(LexError::UnexpectedChar(_, _)) => inspect(true, content="true")
    _ => inspect(false, content="should be UnexpectedChar error")
  }
}
