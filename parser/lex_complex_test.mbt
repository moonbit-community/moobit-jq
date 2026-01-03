///|
/// Lexing complex expressions

test "lex: comment" {
  let tokens = @parser.lex("# comment\n.foo")
  inspect(tokens, content="[TDot, TIdentifier(\"foo\"), TEof]")
}

///|
test "lex: complex expression" {
  let tokens = @parser.lex(".foo | map(.bar) | select(. > 10)")
  inspect(
    tokens,
    content=(
      #|[TDot, TIdentifier("foo"), TPipe, TIdentifier("map"), TLParen, TDot, TIdentifier("bar"), TRParen, TPipe, TIdentifier("select"), TLParen, TDot, TGt, TNumber(10), TRParen, TEof]
    ),
  )
}

///|
test "lex: object construction" {
  let tokens = @parser.lex("{foo: .bar, baz: 42}")
  inspect(
    tokens,
    content=(
      #|[TLBrace, TIdentifier("foo"), TColon, TDot, TIdentifier("bar"), TComma, TIdentifier("baz"), TColon, TNumber(42), TRBrace, TEof]
    ),
  )
}

///|
test "lex: array construction" {
  let tokens = @parser.lex("[1, 2, 3]")
  inspect(
    tokens,
    content="[TLBracket, TNumber(1), TComma, TNumber(2), TComma, TNumber(3), TRBracket, TEof]",
  )
}

///|
test "lex: if-then-else" {
  let tokens = @parser.lex("if .x > 0 then .x else 0 end")
  inspect(
    tokens,
    content=(
      #|[TIf, TDot, TIdentifier("x"), TGt, TNumber(0), TThen, TDot, TIdentifier("x"), TElse, TNumber(0), TEnd, TEof]
    ),
  )
}

///|
test "lex: as expression" {
  let tokens = @parser.lex(". as $x | $x + 1")
  inspect(
    tokens,
    content=(
      #|[TDot, TAs, TVariable("x"), TPipe, TVariable("x"), TPlus, TNumber(1), TEof]
    ),
  )
}

///|
test "lex: reduce expression" {
  let tokens = @parser.lex("reduce .[] as $x (0; . + $x)")
  inspect(
    tokens,
    content=(
      #|[TReduce, TDot, TLBracket, TRBracket, TAs, TVariable("x"), TLParen, TNumber(0), TSemicolon, TDot, TPlus, TVariable("x"), TRParen, TEof]
    ),
  )
}

///|
test "lex: try-catch" {
  let tokens = @parser.lex("try .foo catch \"error\"")
  inspect(
    tokens,
    content="[TTry, TDot, TIdentifier(\"foo\"), TCatch, TString(\"error\"), TEof]",
  )
}

///|
test "lex: whitespace handling" {
  let tokens = @parser.lex("  .foo  \n  |  \t  .bar  ")
  inspect(
    tokens,
    content="[TDot, TIdentifier(\"foo\"), TPipe, TDot, TIdentifier(\"bar\"), TEof]",
  )
}
