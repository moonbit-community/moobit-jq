///|
/// Parse regex-like string built-ins
fn Parser::parse_builtin_string_regex(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "test" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(s)) else {
        raise InvalidSyntax("test expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::Test(s))
    }
    "match" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(s)) else {
        raise InvalidSyntax("match expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::Match(s))
    }
    "capture" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(s)) else {
        raise InvalidSyntax("capture expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::Capture(s))
    }
    "splits" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(s)) else {
        raise InvalidSyntax("splits expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::Splits(s))
    }
    "sub" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(pattern)) else {
        raise InvalidSyntax("sub expects string pattern")
      }
      self.advance()
      self.expect(TSemicolon)
      guard self.current() is Some(TString(replacement)) else {
        raise InvalidSyntax("sub expects string replacement")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::Sub(pattern, replacement))
    }
    "gsub" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(pattern)) else {
        raise InvalidSyntax("gsub expects string pattern")
      }
      self.advance()
      self.expect(TSemicolon)
      guard self.current() is Some(TString(replacement)) else {
        raise InvalidSyntax("gsub expects string replacement")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::GSub(pattern, replacement))
    }
    _ => None
  }
}
