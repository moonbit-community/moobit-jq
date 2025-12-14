///|
fn cov_eval7(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  eval(expr, json_input).collect()
}

///|
test "coverage: leaf_paths includes empty containers" {
  @json.inspect(cov_eval7("leaf_paths", "{}"), content=[[]])
  @json.inspect(cov_eval7("leaf_paths", "[]"), content=[[]])
}

///|
test "coverage: getpath early returns" {
  @json.inspect(cov_eval7("getpath(empty)", "{\"a\": 1}"), content=[null])
  @json.inspect(cov_eval7("getpath(1)", "{\"a\": 1}"), content=[null])
  @json.inspect(cov_eval7("getpath([\"a\"])", "[1, 2]"), content=[null])
  @json.inspect(cov_eval7("getpath([0])", "{\"a\": 1}"), content=[null])
}

///|
test "coverage: setpath edge cases" {
  @json.inspect(cov_eval7("setpath([]; 1)", "{\"a\": 1}"), content=[1])
  @json.inspect(cov_eval7("setpath(empty; 1)", "{\"a\": 1}"), content=[
    { "a": 1 },
  ])
  @json.inspect(cov_eval7("setpath([\"a\"]; empty)", "{\"a\": 1}"), content=[
    { "a": 1 },
  ])
  @json.inspect(cov_eval7("setpath(1; 2)", "{\"a\": 1}"), content=[{ "a": 1 }])
}

///|
test "coverage: delpaths edge cases" {
  @json.inspect(cov_eval7("delpaths(empty)", "{\"a\": 1}"), content=[{ "a": 1 }])
  @json.inspect(cov_eval7("delpaths(1)", "{\"a\": 1}"), content=[{ "a": 1 }])
  @json.inspect(cov_eval7("delpaths([1, 2])", "{\"a\": 1}"), content=[
    { "a": 1 },
  ])
}

///|
test "coverage: until/while exit on empty" {
  @json.inspect(cov_eval7("until(empty; . + 1)", "1"), content=[1])
  @json.inspect(cov_eval7("until(. > 0; empty)", "0"), content=[0])
  @json.inspect(cov_eval7("while(empty; . + 1)", "1"), content=[])
}
