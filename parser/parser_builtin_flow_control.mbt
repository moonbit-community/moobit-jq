///|
/// Parse flow control built-ins
fn Parser::parse_builtin_flow_control(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "limit" => {
      self.expect(TLParen)
      match self.current() {
        Some(TNumber(n)) => {
          self.advance()
          self.expect(TSemicolon)
          let expr = self.parse_pipe()
          self.expect(TRParen)
          Some(@ast.Expr::Limit(n.to_int(), expr))
        }
        _ => raise InvalidSyntax("limit expects number argument")
      }
    }
    "until" => {
      self.expect(TLParen)
      let cond = self.parse_pipe()
      self.expect(TSemicolon)
      let update = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::Until(cond, update))
    }
    "while" => {
      self.expect(TLParen)
      let cond = self.parse_pipe()
      self.expect(TSemicolon)
      let update = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::While(cond, update))
    }
    _ => None
  }
}
