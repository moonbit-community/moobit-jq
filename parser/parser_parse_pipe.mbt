///|
/// Parse pipe expression (lowest precedence)
fn Parser::parse_pipe(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_comma()

  if self.consume(TAs) {
    let var_name = match self.current() {
      Some(TVariable(name)) => {
        self.advance()
        name
      }
      _ => raise InvalidSyntax("Expected variable after 'as'")
    }
    self.expect(TPipe)
    let body = self.parse_pipe()
    return @ast.Expr::As(expr, var_name, body)
  }

  while self.consume(TPipe) {
    let right = self.parse_comma()
    expr = @ast.Expr::Pipe(expr, right)
  }
  expr
}

///|
/// Parse comma expression
fn Parser::parse_comma(self : Parser) -> @ast.Expr raise ParseError {
  let mut expr = self.parse_assignment()
  while self.consume(TComma) {
    let right = self.parse_assignment()
    expr = @ast.Expr::Comma(expr, right)
  }
  expr
}
