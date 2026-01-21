///|
/// Parse control and generator built-ins
fn Parser::parse_builtin_flow(
  self : Parser,
  name : String,
) -> @ast.Expr? raise ParseError {
  if self.parse_builtin_flow_range(name) is Some(expr) {
    return Some(expr)
  }
  if self.parse_builtin_flow_predicates(name) is Some(expr) {
    return Some(expr)
  }
  if self.parse_builtin_flow_control(name) is Some(expr) {
    return Some(expr)
  }
  if self.parse_builtin_flow_reduce(name) is Some(expr) {
    return Some(expr)
  }
  self.parse_builtin_flow_traversal(name)
}
