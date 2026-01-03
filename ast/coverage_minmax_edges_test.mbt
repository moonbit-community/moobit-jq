///|
test "coverage: min_by/max_by empty and invalid key" {
  @json.inspect(coverage_eval("min_by(.)", "[]"), content=[null])
  @json.inspect(coverage_eval("max_by(.)", "[]"), content=[null])
  // Key expression yields empty => null.
  @json.inspect(coverage_eval("min_by(empty)", "[1, 2]"), content=[null])
  @json.inspect(coverage_eval("max_by(empty)", "[1, 2]"), content=[null])
  assert_true((try? coverage_eval("min_by(.)", "1")) is Err(_))
  assert_true((try? coverage_eval("max_by(.)", "1")) is Err(_))
}
