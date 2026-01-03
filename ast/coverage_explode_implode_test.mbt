///|
test "coverage: explode/implode and type mismatches" {
  @json.inspect(coverage_eval("explode", "\"A\""), content=[[65]])
  @json.inspect(coverage_eval("implode", "[65]"), content=["A"])
  // Invalid code point is ignored.
  @json.inspect(coverage_eval("implode", "[1114112]"), content=[""])
  assert_true((try? coverage_eval("explode", "1")) is Err(_))
  assert_true((try? coverage_eval("implode", "\"x\"")) is Err(_))
}
