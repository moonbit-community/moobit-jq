///|
test "coverage: map and min/max edge cases" {
  assert_true((try? coverage_eval("map(.)", "1")) is Err(_))
  @json.inspect(coverage_eval("min", "[]"), content=[null])
  @json.inspect(coverage_eval("max", "[]"), content=[null])
}

///|
test "coverage: control flow fallbacks" {
  @json.inspect(coverage_eval("if empty then 1 else 2 end", "null"), content=[2])
  @json.inspect(coverage_eval("try (1 / 0)", "null"), content=[])
  @json.inspect(coverage_eval("empty // 2", "null"), content=[2])
}

///|
test "coverage: undefined variable" {
  assert_true((try? coverage_eval("$missing", "null")) is Err(_))
}

///|
test "coverage: function argument handling" {
  assert_true(
    (try? coverage_eval("def f(x; y): $x + $y; f(1)", "null")) is Err(_),
  )
  @json.inspect(coverage_eval("def id(x): $x; id(empty)", "null"), content=[
    null,
  ])
}

///|
test "coverage: reduce and assignment edges" {
  @json.inspect(coverage_eval("reduce .[] as $x (empty; . + $x)", "[1, 2]"), content=[
    null,
  ])
  @json.inspect(coverage_eval(".a = empty", "{\"a\": 1}"), content=[{ "a": 1 }])
}
