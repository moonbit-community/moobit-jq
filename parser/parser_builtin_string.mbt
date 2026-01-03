///|
/// Parse string built-ins
fn Parser::parse_builtin_string(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match self.parse_builtin_string_core(name) {
    Some(expr) => Some(expr)
    None =>
      match self.parse_builtin_string_trim(name) {
        Some(expr) => Some(expr)
        None =>
          match self.parse_builtin_string_codec(name) {
            Some(expr) => Some(expr)
            None => self.parse_builtin_string_regex(name)
          }
      }
  }
}
