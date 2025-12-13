///|
/// Parse a jq query into an AST expression.
pub fn parse(query : String) -> @ast.Expr raise {
  @parser.parse(query)
}

///|
/// Evaluate a jq expression against an input JSON value.
pub fn eval(expr : @ast.Expr, input : Json) -> Iterator[Json] raise {
  @interpreter.eval(expr, input)
}

///|
/// Parse + evaluate a jq query against an input JSON string.
pub fn run(query : String, input : String) -> Iterator[Json] raise {
  let expr = @parser.parse(query)
  let json = @moonjq_json.parse(input)
  @interpreter.eval(expr, json)
}
