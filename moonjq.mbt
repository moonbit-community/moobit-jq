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

///|
/// Apply the query to newline-delimited JSON logs, skipping invalid lines.
pub fn Query::eval_logs(self : Query, logs : String) -> Iterator[Json] raise {
  let aggregated : Array[Json] = []
  for raw_line in logs.split("\n") {
    let line = match raw_line.strip_suffix("\r"[:]) {
      Some(rest) => rest
      None => raw_line
    }
    if line.length() == 0 {
      continue
    }
    let json_value = @json.parse(line) catch { _ => continue }
    for value in @ast.eval(self.expr, json_value) {
      aggregated.push(value)
    }
  }
  aggregated.iterator()
}
