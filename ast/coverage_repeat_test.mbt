///|
test "coverage: repeat with limit and empty inner" {
  @json.inspect(coverage_eval("limit(5; repeat(1))", "null"), content=[
    1, 1, 1, 1, 1,
  ])
  @json.inspect(coverage_eval("limit(5; repeat(empty))", "null"), content=[])
}
