///|
test "coverage: select(empty) yields no outputs" {
  @json.inspect(coverage_eval(".[] | select(empty)", "[1, 2, 3]"), content=[])
}

///|
test "coverage: try-catch executes catch branch" {
  @json.inspect(coverage_eval("try (1 / 0) catch 42", "null"), content=[42])
}
