///|
/// Parse core built-ins
fn Parser::parse_builtin_core(_self : Parser, name : String) -> @ast.Expr? {
  match name {
    "length" => Some(@ast.Expr::Length)
    "keys" => Some(@ast.Expr::Keys)
    "values" => Some(@ast.Expr::Values)
    "type" => Some(@ast.Expr::Type)
    "empty" => Some(@ast.Expr::Empty)
    "not" => Some(@ast.Expr::Not)
    _ => None
  }
}
