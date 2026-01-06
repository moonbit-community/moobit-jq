///|
/// Lexing operators and punctuation
test "lex: pipe operator" {
  let tokens = @parser.lex(".foo | .bar")
  inspect(
    tokens,
    content="[TDot, TIdentifier(\"foo\"), TPipe, TDot, TIdentifier(\"bar\"), TEof]",
  )
}

///|
test "lex: arithmetic operators" {
  let tokens = @parser.lex("+ - * / %")
  inspect(tokens, content="[TPlus, TMinus, TStar, TSlash, TPercent, TEof]")
}

///|
test "lex: comparison operators" {
  let tokens = @parser.lex("== != < <= > >=")
  inspect(tokens, content="[TEq, TNeq, TLt, TLe, TGt, TGe, TEof]")
}

///|
test "lex: comma and semicolon" {
  let tokens = @parser.lex(", ;")
  inspect(tokens, content="[TComma, TSemicolon, TEof]")
}

///|
test "lex: brackets and braces" {
  let tokens = @parser.lex("( ) [ ] { }")
  inspect(
    tokens,
    content="[TLParen, TRParen, TLBracket, TRBracket, TLBrace, TRBrace, TEof]",
  )
}

///|
test "lex: assignment operators" {
  let tokens = @parser.lex("= |= //")
  inspect(tokens, content="[TAssign, TUpdate, TAlternative, TEof]")
}

///|
test "lex: dot dot" {
  let tokens = @parser.lex("..")
  inspect(tokens, content="[TDotDot, TEof]")
}

///|
test "lex: optional operator" {
  let tokens = @parser.lex(".foo?")
  inspect(tokens, content="[TDot, TIdentifier(\"foo\"), TQuestion, TEof]")
}
