///|
/// Compiled jq query wrapper so the AST stays internal.
pub struct Query {
  expr : @ast.Expr
}

///|
/// Compile a jq query string into a reusable Query.
pub fn parse(query : String) -> Query raise {
  Query::{ expr: @parser.parse(query) }
}

///|
/// Evaluate a compiled query against an input JSON value and stream results.
pub fn eval(query : Query, input : Json) -> Iterator[Json] raise {
  query.eval(input)
}

///|
/// Evaluate a compiled query and collect all results eagerly.
pub fn eval_all(query : Query, input : Json) -> Array[Json] raise {
  query.eval_all(input)
}

///|
/// Parse + evaluate a jq query against a JSON string input, collecting results.
pub fn run(query : String, input : String) -> Array[Json] raise {
  let compiled = parse(query)
  let json = @json.parse(input[:])
  compiled.eval_all(json)
}

///|
/// Evaluate a compiled query against an already parsed Json input.
pub fn run_json(query : Query, input : Json) -> Array[Json] raise {
  query.eval_all(input)
}

///|
/// Methods on Query for direct control.
pub fn Query::eval(self : Query, input : Json) -> Iterator[Json] raise {
  @ast.eval(self.expr, input)
}

///|
pub fn Query::eval_all(self : Query, input : Json) -> Array[Json] raise {
  self.eval(input).collect()
}
