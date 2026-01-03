///|
/// Parse logical or
fn Parser::parse_or(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_and()
  while self.consume(TOr) {
    expr = @ast.Expr::Operation(expr, @ast.BinaryOp::Or, self.parse_and())
  }
  expr
}

///|
/// Parse logical and
fn Parser::parse_and(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_comparison()
  while self.consume(TAnd) {
    expr = @ast.Expr::Operation(
      expr,
      @ast.BinaryOp::And,
      self.parse_comparison(),
    )
  }
  expr
}

///|
/// Parse comparison operators
fn Parser::parse_comparison(self : Parser) -> @ast.Expr raise ParseError {
  let expr = self.parse_additive()
  match self.current() {
    Some(TEq) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::Equal, self.parse_additive())
    }
    Some(TNeq) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::NotEqual, self.parse_additive())
    }
    Some(TLt) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::LessThan, self.parse_additive())
    }
    Some(TLe) => {
      self.advance()
      @ast.Expr::Operation(expr, @ast.BinaryOp::LessEq, self.parse_additive())
    }
    Some(TGt) => {
      self.advance()
      @ast.Expr::Operation(
        expr,
        @ast.BinaryOp::GreaterThan,
        self.parse_additive(),
      )
    }
    Some(TGe) => {
      self.advance()
      @ast.Expr::Operation(
        expr,
        @ast.BinaryOp::GreaterEq,
        self.parse_additive(),
      )
    }
    _ => expr
  }
}
