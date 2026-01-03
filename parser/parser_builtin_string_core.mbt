///|
/// Parse core string built-ins
fn Parser::parse_builtin_string_core(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "split" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(sep)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::Split(sep))
        }
        _ => raise InvalidSyntax("split expects string argument")
      }
    }
    "join" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(sep)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::Join(sep))
        }
        _ => raise InvalidSyntax("join expects string argument")
      }
    }
    "startswith" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(prefix)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::StartsWith(prefix))
        }
        _ => raise InvalidSyntax("startswith expects string argument")
      }
    }
    "endswith" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(suffix)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::EndsWith(suffix))
        }
        _ => raise InvalidSyntax("endswith expects string argument")
      }
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
