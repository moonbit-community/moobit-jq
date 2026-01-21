///|
/// Parse entry point
pub fn parse(input : String) -> @ast.Expr raise {
  let tokens = lex(input)
  let parser = Parser::new(tokens)
  parser.parse_definitions()
}

///|
/// Parse function definitions followed by expression
fn Parser::parse_definitions(self : Parser) -> @ast.Expr raise ParseError {
  let defs : Array[@ast.Expr] = []
  while self.current() == Some(TDef) {
    defs.push(self.parse_function_def())
  }
  let main_expr = self.parse_pipe()
  // Chain definitions with main expression so they execute in order
  match defs {
    [] => main_expr
    // Fold defs from right to left so they execute in order
    _ =>
      defs
      .rev()
      .fold(init=main_expr, fn(expr, def) { @ast.Expr::Pipe(def, expr) })
  }
}
