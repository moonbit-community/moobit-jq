///|
test "coverage: contains/inside/has on arrays and objects" {
  @json.inspect(coverage_eval("contains(2)", "[1, 2, 3]"), content=[true])
  @json.inspect(coverage_eval("contains(\"a\")", "{\"a\": 1}"), content=[true])
  @json.inspect(coverage_eval("\"a\" | inside({\"a\": 1})", "null"), content=[
    true,
  ])
  @json.inspect(coverage_eval("[1, 2] | inside([2, 1, 3])", "null"), content=[
    true,
  ])
  @json.inspect(coverage_eval("[1, 9] | inside([2, 1, 3])", "null"), content=[
    false,
  ])
  @json.inspect(coverage_eval("has(\"1\")", "[10, 20]"), content=[true])
  @json.inspect(coverage_eval("has(\"-1\")", "[10, 20]"), content=[true])
  @json.inspect(coverage_eval("has(\"2\")", "[10, 20]"), content=[false])
  @json.inspect(coverage_eval("has(\"x\")", "[10, 20]"), content=[false])
}
