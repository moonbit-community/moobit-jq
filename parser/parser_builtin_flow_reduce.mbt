///|
/// Parse reduce and foreach built-ins
fn Parser::parse_builtin_flow_reduce(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "reduce" => {
      self.expect(TLParen)
      let gen_expr = self.parse_postfix()
      self.expect(TAs)
      guard self.current() is Some(TVariable(var_name)) else {
        raise InvalidSyntax("reduce expects variable after as")
      }
      self.advance()
      self.expect(TLParen)
      let init_expr = self.parse_pipe()
      self.expect(TSemicolon)
      let update_expr = self.parse_pipe()
      self.expect(TRParen)
      self.expect(TRParen)
      Some(@ast.Expr::Reduce(gen_expr, var_name, init_expr, update_expr))
    }
    "foreach" => {
      self.expect(TLParen)
      let gen_expr = self.parse_postfix()
      self.expect(TAs)
      guard self.current() is Some(TVariable(var_name)) else {
        raise InvalidSyntax("foreach expects variable after as")
      }
      self.advance()
      self.expect(TLParen)
      let init_expr = self.parse_pipe()
      self.expect(TSemicolon)
      let update_expr = self.parse_pipe()
      let extract_expr = if self.consume(TSemicolon) {
        Some(self.parse_pipe())
      } else {
        None
      }
      self.expect(TRParen)
      self.expect(TRParen)
      Some(
        @ast.Expr::Foreach(
          gen_expr, var_name, init_expr, update_expr, extract_expr,
        ),
      )
    }
    _ => None
  }
}
