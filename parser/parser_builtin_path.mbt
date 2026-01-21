///|
/// Parse path built-ins
fn Parser::parse_builtin_path(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "paths" =>
      if self.consume(TLParen) {
        let expr = self.parse_pipe()
        self.expect(TRParen)
        Some(@ast.Expr::PathsWithFilter(expr))
      } else {
        Some(@ast.Expr::Paths)
      }
    "leaf_paths" => Some(@ast.Expr::LeafPaths)
    "getpath" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::GetPath(expr))
    }
    "setpath" => {
      self.expect(TLParen)
      let path = self.parse_pipe()
      self.expect(TSemicolon)
      let value = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::SetPath(path, value))
    }
    "delpaths" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::DelPaths(expr))
    }
    _ => None
  }
}
