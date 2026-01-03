///|
/// Parse control and generator built-ins
fn Parser::parse_builtin_flow(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  match self.parse_builtin_flow_range(name) {
    Some(expr) => Some(expr)
    None =>
      match self.parse_builtin_flow_predicates(name) {
        Some(expr) => Some(expr)
        None =>
          match self.parse_builtin_flow_control(name) {
            Some(expr) => Some(expr)
            None =>
              match self.parse_builtin_flow_reduce(name) {
                Some(expr) => Some(expr)
                None => self.parse_builtin_flow_traversal(name)
              }
          }
      }
  }
}
