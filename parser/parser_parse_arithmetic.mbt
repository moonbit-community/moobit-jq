///|
/// Parse additive operators
fn Parser::parse_additive(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_multiplicative()
  while true {
    match self.current() {
      Some(TPlus) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Add,
          self.parse_multiplicative(),
        )
      }
      Some(TMinus) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Subtract,
          self.parse_multiplicative(),
        )
      }
      _ => break
    }
  }
  expr
}

///|
/// Parse multiplicative operators
fn Parser::parse_multiplicative(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_unary()
  while true {
    match self.current() {
      Some(TStar) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Multiply,
          self.parse_unary(),
        )
      }
      Some(TSlash) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Divide,
          self.parse_unary(),
        )
      }
      Some(TPercent) => {
        self.advance()
        expr = @ast.Expr::Operation(
          expr,
          @ast.BinaryOp::Modulo,
          self.parse_unary(),
        )
      }
      _ => break
    }
  }
  expr
}

///|
/// Parse unary operators
fn Parser::parse_unary(self : Parser) -> @ast.Expr raise ParseError {
  if self.consume(TNot) {
    @ast.Expr::Not
  } else {
    self.parse_postfix()
  }
}
