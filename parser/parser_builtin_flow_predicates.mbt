///|
/// Parse flow predicate built-ins
fn Parser::parse_builtin_flow_predicates(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "any" =>
      if self.consume(TLParen) {
        let gen_expr = self.parse_pipe()
        self.expect(TSemicolon)
        let cond_expr = self.parse_pipe()
        self.expect(TRParen)
        Some(@ast.Expr::AnyGen(gen_expr, cond_expr))
      } else {
        Some(@ast.Expr::Any)
      }
    "all" =>
      if self.consume(TLParen) {
        let gen_expr = self.parse_pipe()
        self.expect(TSemicolon)
        let cond_expr = self.parse_pipe()
        self.expect(TRParen)
        Some(@ast.Expr::AllGen(gen_expr, cond_expr))
      } else {
        Some(@ast.Expr::All)
      }
    _ => None
  }
}
