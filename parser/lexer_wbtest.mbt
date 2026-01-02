///|
test "wb: lexer invalid number slice" {
  let lexer = Lexer::new("1")
  lexer.pos = 2
  assert_true((try? lexer.lex_number()) is Err(_))
}

///|
test "wb: lexer invalid number parse" {
  let lexer = Lexer::new("-")
  assert_true((try? lexer.lex_number()) is Err(_))
}
