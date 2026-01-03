///|
/// Parse recursion and traversal built-ins
fn Parser::parse_builtin_flow_traversal(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "recurse" =>
      if self.consume(TLParen) {
        let f = self.parse_pipe()
        self.expect(TSemicolon)
        let cond = self.parse_pipe()
        self.expect(TRParen)
        Some(@ast.Expr::RecurseWith(f, cond))
      } else {
        Some(@ast.Expr::Recurse)
      }
    "walk" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::Walk(expr))
    }
    _ => None
  }
}
