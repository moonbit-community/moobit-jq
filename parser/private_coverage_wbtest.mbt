///|
fn reduce_tokens() -> Array[Token] {
  [
    TLParen,
    TDot,
    TAs,
    TVariable("x"),
    TLParen,
    TNumber(0.0),
    TSemicolon,
    TDot,
    TRParen,
    TRParen,
  ]
}

///|
fn foreach_tokens(with_extract : Bool) -> Array[Token] {
  let tokens = [
    TLParen,
    TDot,
    TAs,
    TVariable("x"),
    TLParen,
    TNumber(0.0),
    TSemicolon,
    TDot,
  ]
  if with_extract {
    tokens.push(TSemicolon)
    tokens.push(TDot)
  }
  tokens.push(TRParen)
  tokens.push(TRParen)
  tokens
}

///|
test "wb: parser none branches" {
  let parser = Parser::new([])
  assert_true(parser.current() is None)
  assert_true(not(parser.check(TDot)))
  assert_true((try? parser.expect(TDot)) is Err(_))
  assert_true((try? parser.parse_primary()) is Err(_))
}

///|
test "wb: parse_builtin not" {
  let parser = Parser::new([])
  let expr = parser.parse_builtin("not")
  assert_true(expr is @ast.Expr::Not)
}

///|
test "wb: parse_builtin reduce success" {
  let parser = Parser::new(reduce_tokens())
  let expr = parser.parse_builtin("reduce")
  assert_true(expr is @ast.Expr::Reduce(_, _, _, _))
}

///|
test "wb: parse_builtin reduce missing variable" {
  let parser = Parser::new([TLParen, TDot, TAs, TIdentifier("x")])
  assert_true((try? parser.parse_builtin("reduce")) is Err(_))
}

///|
test "wb: parse_builtin foreach success with extract" {
  let parser = Parser::new(foreach_tokens(true))
  let expr = parser.parse_builtin("foreach")
  assert_true(expr is @ast.Expr::Foreach(_, _, _, _, Some(_)))
}

///|
test "wb: parse_builtin foreach success without extract" {
  let parser = Parser::new(foreach_tokens(false))
  let expr = parser.parse_builtin("foreach")
  assert_true(expr is @ast.Expr::Foreach(_, _, _, _, None))
}

///|
test "wb: parse_builtin foreach missing variable" {
  let parser = Parser::new([TLParen, TDot, TAs, TIdentifier("x")])
  assert_true((try? parser.parse_builtin("foreach")) is Err(_))
}
