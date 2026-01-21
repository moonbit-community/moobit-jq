///|
/// Parse core string built-ins
fn Parser::parse_builtin_string_core(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "split" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(sep)) else {
        raise InvalidSyntax("split expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::Split(sep))
    }
    "join" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(sep)) else {
        raise InvalidSyntax("join expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::Join(sep))
    }
    "startswith" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(prefix)) else {
        raise InvalidSyntax("startswith expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::StartsWith(prefix))
    }
    "endswith" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(suffix)) else {
        raise InvalidSyntax("endswith expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::EndsWith(suffix))
    }
    "contains" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::Contains(expr))
    }
    "inside" => {
      self.expect(TLParen)
      let expr = self.parse_pipe()
      self.expect(TRParen)
      Some(@ast.Expr::Inside(expr))
    }
    _ => None
  }
}
