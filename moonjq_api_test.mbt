///|
fn collect(it : Iterator[Json]) -> Array[Json] {
  it.collect()
}

///|
test "api: parse succeeds" {
  let result = try? parse(".a")
  assert_true(result is Ok(_))
}

///|
test "api: eval runs expression" {
  let expr = parse(".a")
  let input = @json.parse("{\"a\": 1}"[:])
  @json.inspect(collect(eval(expr, input)), content=[1])
}

///|
test "api: run parses and evaluates" {
  @json.inspect(collect(run(".a", "{\"a\": 1}")), content=[1])
}
