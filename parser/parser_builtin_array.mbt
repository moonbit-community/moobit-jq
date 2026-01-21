///|
/// Parse array built-ins
fn Parser::parse_builtin_array(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "map" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::Map(expr))
    }
    "select" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::Select(expr))
    }
    "sort" => Some(@ast.Expr::Sort)
    "reverse" => Some(@ast.Expr::Reverse)
    "flatten" =>
      if self.consume(TLParen) {
        let depth = if self.current() is Some(TNumber(n)) {
          self.advance()
          Some(n.to_int())
        } else {
          None
        }
        self.expect(TRParen)
        Some(@ast.Expr::Flatten(depth))
      } else {
        Some(@ast.Expr::Flatten(None))
      }
    "unique" => Some(@ast.Expr::Unique)
    "unique_by" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::UniqueBy(expr))
    }
    "combinations" => Some(@ast.Expr::Combinations)
    "transpose" => Some(@ast.Expr::Transpose)
    "indices" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::IndicesOf(expr))
    }
    "index" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::IndexOf(expr))
    }
    "sort_by" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::SortBy(expr))
    }
    "group_by" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::GroupBy(expr))
    }
    "nth" => {
      self.expect(TLParen)
      guard self.current() is Some(TNumber(n)) else {
        raise InvalidSyntax("nth expects number argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::Nth(n.to_int()))
    }
    "rindex" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::RIndex(expr))
    }
    _ => None
  }
}
