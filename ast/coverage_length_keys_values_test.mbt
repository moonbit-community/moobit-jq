///|
test "coverage: length/keys/values coverage and mismatches" {
  json_inspect(coverage_eval("length", "{\"a\": 1, \"b\": 2}"), content=[2])
  json_inspect(coverage_eval("length", "null"), content=[0])
  assert_true((try? coverage_eval("length", "true")) is Err(_))
  json_inspect(coverage_eval("keys", "[10, 20]"), content=[[0, 1]])
  json_inspect(coverage_eval("values", "{\"a\": 1, \"b\": 2}"), content=[[1, 2]])
  assert_true((try? coverage_eval("values", "true")) is Err(_))
  assert_true((try? coverage_eval("keys", "true")) is Err(_))
}
