///|
/// Parse pipe expression (lowest precedence)
fn Parser::parse_pipe(self : Parser) -> @ast.Expr raise ParseError {
  let expr = self.parse_comma()
  if self.consume(TAs) {
    guard self.current() is Some(TVariable(var_name)) else {
      raise InvalidSyntax("Expected variable after 'as'")
    }
    self.advance()
    self.expect(TPipe)
    let body = self.parse_pipe()
    return @ast.Expr::As(expr, var_name, body)
  }
  loop expr {
    current =>
      if self.consume(TPipe) {
        let right = self.parse_comma()
        continue @ast.Expr::Pipe(current, right)
      } else {
        current
      }
  }
}

///|
/// Parse comma expression
fn Parser::parse_comma(self : Parser) -> @ast.Expr raise ParseError {
  loop self.parse_assignment() {
    current =>
      if self.consume(TComma) {
        let right = self.parse_assignment()
        continue @ast.Expr::Comma(current, right)
      } else {
        current
      }
  }
}
