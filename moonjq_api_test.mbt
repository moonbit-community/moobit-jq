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
test "api: eval streams results" {
  let query = parse(".a")
  let input = @json.parse("{\"a\": 1}"[:])
  @json.inspect(collect(eval(query, input)), content=[1])
}

///|
test "api: eval_all collects results" {
  let query = parse(".a")
  let input = @json.parse("{\"a\": 1}"[:])
  @json.inspect(eval_all(query, input), content=[1])
}

///|
test "api: run parses strings and collects" {
  @json.inspect(run(".a", "{\"a\": 1}"), content=[1])
}

///|
test "api: run_json reuses compiled query" {
  let query = parse(".a")
  let json = @json.parse("{\"a\": 2}"[:])
  @json.inspect(run_json(query, json), content=[2])
}
