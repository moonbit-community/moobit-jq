///|
/// Lexing control flow expressions
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
test "lex: try-catch" {
  let tokens = @parser.lex("try .foo catch \"error\"")
  inspect(
    tokens,
    content="[TTry, TDot, TIdentifier(\"foo\"), TCatch, TString(\"error\"), TEof]",
  )
}
