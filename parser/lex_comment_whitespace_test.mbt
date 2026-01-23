///|
/// Lexing comments and whitespace
test "lex: comment" {
  let tokens = @parser.lex("# comment\n.foo")
  debug_inspect(tokens, content="[TDot, TIdentifier(\"foo\"), TEof]")
}

///|
test "lex: whitespace handling" {
  let tokens = @parser.lex("  .foo  \n  |  \t  .bar  ")
  debug_inspect(
    tokens,
    content="[TDot, TIdentifier(\"foo\"), TPipe, TDot, TIdentifier(\"bar\"), TEof]",
  )
}
