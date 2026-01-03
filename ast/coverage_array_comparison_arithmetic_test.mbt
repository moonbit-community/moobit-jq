///|
test "coverage: array comparisons exercise element and length ordering" {
  @json.inspect(coverage_eval("[1] < [1, 2]", "null"), content=[true])
  @json.inspect(coverage_eval("[1, 0] < [1, 2]", "null"), content=[true])
}

///|
test "coverage: invalid arithmetic operations error" {
  assert_true((try? coverage_eval("1 + []", "null")) is Err(_))
  assert_true((try? coverage_eval("1 - \"x\"", "null")) is Err(_))
  assert_true((try? coverage_eval("1 * {}", "null")) is Err(_))
  assert_true((try? coverage_eval("1 / []", "null")) is Err(_))
}
