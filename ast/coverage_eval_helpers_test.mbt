///|
/// Helper for coverage tests
fn coverage_eval(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  @ast.eval(expr, json_input).collect()
}
