///|
/// Lexing object construction
test "lex: object construction" {
  let tokens = @parser.lex("{foo: .bar, baz: 42}")
  debug_inspect(
    tokens,
    content=(
      #|[TLBrace, TIdentifier("foo"), TColon, TDot, TIdentifier("bar"), TComma, TIdentifier("baz"), TColon, TNumber(42), TRBrace, TEof]
    ),
  )
}

///|
/// Lexing array construction
test "lex: array construction" {
  let tokens = @parser.lex("[1, 2, 3]")
  debug_inspect(
    tokens,
    content="[TLBracket, TNumber(1), TComma, TNumber(2), TComma, TNumber(3), TRBracket, TEof]",
  )
}
