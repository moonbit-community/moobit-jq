///|
test "coverage: combinations empty and type mismatch" {
  @json.inspect(coverage_eval("combinations", "[]"), content=[])
  assert_true((try? coverage_eval("combinations", "1")) is Err(_))
}
