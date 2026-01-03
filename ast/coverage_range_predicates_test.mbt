///|
test "coverage: range variants" {
  @json.inspect(coverage_eval("range(1; 4)", "null"), content=[1, 2, 3])
  @json.inspect(coverage_eval("range(0; 5; 2)", "null"), content=[0, 2, 4])
  @json.inspect(coverage_eval("range(5; 0; -2)", "null"), content=[5, 3, 1])
  assert_true((try? coverage_eval("range(\"a\"; 4)", "null")) is Err(_))
}

///|
test "coverage: first/last with generator" {
  @json.inspect(coverage_eval("first(.[])", "[1, 2, 3]"), content=[1])
  @json.inspect(coverage_eval("last(.[])", "[1, 2, 3]"), content=[3])
  @json.inspect(coverage_eval("first(empty)", "null"), content=[])
  @json.inspect(coverage_eval("last(empty)", "null"), content=[])
}

///|
test "coverage: any/all generator variants" {
  @json.inspect(coverage_eval("any(.[]; . > 2)", "[1, 3]"), content=[true])
  @json.inspect(coverage_eval("all(.[]; . > 2)", "[1, 3]"), content=[false])
  @json.inspect(coverage_eval("any(.[]; empty)", "[1, 3]"), content=[false])
  @json.inspect(coverage_eval("all(.[]; empty)", "[1, 3]"), content=[false])
}
