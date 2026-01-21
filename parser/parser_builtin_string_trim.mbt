///|
/// Parse string trim and case built-ins
fn Parser::parse_builtin_string_trim(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "ltrimstr" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(s)) else {
        raise InvalidSyntax("ltrimstr expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::LTrimStr(s))
    }
    "rtrimstr" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(s)) else {
        raise InvalidSyntax("rtrimstr expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::RTrimStr(s))
    }
    "ascii_upcase" => Some(@ast.Expr::AsciiUpcase)
    "ascii_downcase" => Some(@ast.Expr::AsciiDowncase)
    _ => None
  }
}
