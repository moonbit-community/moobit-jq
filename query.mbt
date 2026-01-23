///|
/// Compiled jq query wrapper so the AST stays internal.
pub struct Query {
  expr : @ast.Expr
} derive(Debug)

///|
/// Methods on Query for direct control.
pub fn Query::eval(self : Query, input : Json) -> Iter[Json] raise {
  @ast.eval(self.expr, input)
}

///|
pub fn Query::eval_all(self : Query, input : Json) -> Array[Json] raise {
  self.eval(input).collect()
}

///|
/// Apply the query to newline-delimited JSON logs, skipping invalid lines.
pub fn Query::eval_logs(self : Query, logs : String) -> Iter[Json] raise {
  let aggregated : Array[Json] = []
  for raw_line in logs.split("\n") {
    let line = raw_line.strip_suffix("\r").unwrap_or(raw_line)
    if line.is_empty() {
      continue
    }
    let json_value = @json.parse(line) catch { _ => continue }
    for value in self.eval(json_value) {
      aggregated.push(value)
    }
  }
  aggregated.iter()
}
