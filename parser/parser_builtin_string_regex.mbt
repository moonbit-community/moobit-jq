///|
/// Parse regex-like string built-ins
fn Parser::parse_builtin_string_regex(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "test" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(s)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::Test(s))
        }
        _ => raise InvalidSyntax("test expects string argument")
      }
    }
    "match" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(s)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::Match(s))
        }
        _ => raise InvalidSyntax("match expects string argument")
      }
    }
    "capture" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(s)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::Capture(s))
        }
        _ => raise InvalidSyntax("capture expects string argument")
      }
    }
    "splits" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(s)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::Splits(s))
        }
        _ => raise InvalidSyntax("splits expects string argument")
      }
    }
    "sub" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(pattern)) => {
          self.advance()
          self.expect(TSemicolon)
          match self.current() {
            Some(TString(replacement)) => {
              self.advance()
              self.expect(TRParen)
              Some(@ast.Expr::Sub(pattern, replacement))
            }
            _ => raise InvalidSyntax("sub expects string replacement")
          }
        }
        _ => raise InvalidSyntax("sub expects string pattern")
      }
    }
    "gsub" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(pattern)) => {
          self.advance()
          self.expect(TSemicolon)
          match self.current() {
            Some(TString(replacement)) => {
              self.advance()
              self.expect(TRParen)
              Some(@ast.Expr::GSub(pattern, replacement))
            }
            _ => raise InvalidSyntax("gsub expects string replacement")
          }
        }
        _ => raise InvalidSyntax("gsub expects string pattern")
      }
    }
    _ => None
  }
}
