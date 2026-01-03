///|
/// Parse string trim and case built-ins
fn Parser::parse_builtin_string_trim(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "ltrimstr" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(s)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::LTrimStr(s))
        }
        _ => raise InvalidSyntax("ltrimstr expects string argument")
      }
    }
    "rtrimstr" => {
      self.expect(TLParen)
      match self.current() {
        Some(TString(s)) => {
          self.advance()
          self.expect(TRParen)
          Some(@ast.Expr::RTrimStr(s))
        }
        _ => raise InvalidSyntax("rtrimstr expects string argument")
      }
    }
    "ascii_upcase" => Some(@ast.Expr::AsciiUpcase)
    "ascii_downcase" => Some(@ast.Expr::AsciiDowncase)
    _ => None
  }
}
