///|
test "coverage: fromjson parses and errors" {
  @json.inspect(coverage_eval("fromjson", "\"{\\\"a\\\": 1}\""), content=[
    { "a": 1 },
  ])
  assert_true((try? coverage_eval("fromjson", "\"{\"")) is Err(_))
  assert_true((try? coverage_eval("fromjson", "1")) is Err(_))
}
