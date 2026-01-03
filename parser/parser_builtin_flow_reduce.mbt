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
      match self.current() {
        Some(TVariable(var_name)) => {
          self.advance()
          self.expect(TLParen)
          let init_expr = self.parse_pipe()
          self.expect(TSemicolon)
          let update_expr = self.parse_pipe()
          self.expect(TRParen)
          self.expect(TRParen)
          Some(@ast.Expr::Reduce(gen_expr, var_name, init_expr, update_expr))
        }
        _ => raise InvalidSyntax("reduce expects variable after as")
      }
    }
    "foreach" => {
      self.expect(TLParen)
      let gen_expr = self.parse_postfix()
      self.expect(TAs)
      match self.current() {
        Some(TVariable(var_name)) => {
          self.advance()
          self.expect(TLParen)
          let init_expr = self.parse_pipe()
          self.expect(TSemicolon)
          let update_expr = self.parse_pipe()
          let extract_expr = match self.current() {
            Some(TSemicolon) => {
              self.advance()
              Some(self.parse_pipe())
            }
            _ => None
          }
          self.expect(TRParen)
          self.expect(TRParen)
          Some(
            @ast.Expr::Foreach(
              gen_expr,
              var_name,
              init_expr,
              update_expr,
              extract_expr,
            ),
          )
        }
        _ => raise InvalidSyntax("foreach expects variable after as")
      }
    }
    _ => None
  }
}
