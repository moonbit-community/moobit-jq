///|
/// Parse string codec built-ins
fn Parser::parse_builtin_string_codec(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match name {
    "explode" => Some(@ast.Expr::Explode)
    "implode" => Some(@ast.Expr::Implode)
    "tojson" => Some(@ast.Expr::ToJsonString)
    "fromjson" => Some(@ast.Expr::FromJsonString)
    "scan" => {
      self.expect(TLParen)
      guard self.current() is Some(TString(s)) else {
        raise InvalidSyntax("scan expects string argument")
      }
      self.advance()
      self.expect(TRParen)
      Some(@ast.Expr::Scan(s))
    }
    _ => None
  }
}
