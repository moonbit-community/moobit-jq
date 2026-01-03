///|
/// Parse flow predicate built-ins
fn Parser::parse_builtin_flow_predicates(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "any" =>
      match self.current() {
        Some(TLParen) => {
          self.advance()
          let gen_expr = self.parse_pipe()
          match self.current() {
            Some(TSemicolon) => {
              self.advance()
              let cond_expr = self.parse_pipe()
              self.expect(TRParen)
              Some(@ast.Expr::AnyGen(gen_expr, cond_expr))
            }
            _ => raise InvalidSyntax("any(gen; cond) expects semicolon")
          }
        }
        _ => Some(@ast.Expr::Any)
      }
    "all" =>
      match self.current() {
        Some(TLParen) => {
          self.advance()
          let gen_expr = self.parse_pipe()
          match self.current() {
            Some(TSemicolon) => {
              self.advance()
              let cond_expr = self.parse_pipe()
              self.expect(TRParen)
              Some(@ast.Expr::AllGen(gen_expr, cond_expr))
            }
            _ => raise InvalidSyntax("all(gen; cond) expects semicolon")
          }
        }
        _ => Some(@ast.Expr::All)
      }
    _ => None
  }
}
