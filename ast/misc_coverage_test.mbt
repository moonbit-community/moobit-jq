///|
test "coverage: .[] iterates object values" {
  // Object iteration preserves insertion order.
  @json.inspect(coverage_eval(".[]", "{\"a\": 1, \"b\": 2}"), content=[1, 2])
}

///|
test "coverage: index on non-array yields nulls" {
  @json.inspect(coverage_eval(".[0, 1]", "{\"a\": 1}"), content=[null, null])
}

///|
test "coverage: slice on non-array yields null" {
  @json.inspect(coverage_eval(".[1:2]", "1"), content=[null])
}

///|
test "coverage: optional suppresses evaluation errors" {
  @json.inspect(coverage_eval("(1 / 0)?", "null"), content=[])
}

///|
test "coverage: in(array) checks index bounds" {
  @json.inspect(coverage_eval("0 | in([10, 20])", "null"), content=[true])
  @json.inspect(coverage_eval("1 | in([10, 20])", "null"), content=[true])
  @json.inspect(coverage_eval("2 | in([10, 20])", "null"), content=[false])
  @json.inspect(coverage_eval("-1 | in([10, 20])", "null"), content=[true])
}

///|
test "coverage: object-object comparison uses object ordering" {
  @json.inspect(coverage_eval("{\"a\":1} < {\"b\":2}", "null"), content=[false])
}

///|
test "coverage: comparisons across JSON types" {
  @json.inspect(coverage_eval("false < 0", "null"), content=[true])
  @json.inspect(coverage_eval("0 > false", "null"), content=[true])
  @json.inspect(coverage_eval("0 < \"x\"", "null"), content=[true])
  @json.inspect(coverage_eval("\"x\" > 0", "null"), content=[true])
  @json.inspect(coverage_eval("\"x\" < [0]", "null"), content=[true])
  @json.inspect(coverage_eval("[0] > \"x\"", "null"), content=[true])
  @json.inspect(coverage_eval("[0] < {\"a\":1}", "null"), content=[true])
  @json.inspect(coverage_eval("{\"a\":1} > [0]", "null"), content=[true])
}

///|
test "coverage: foreach copies env bindings and functions" {
  @json.inspect(
    coverage_eval(
      "def f: $x; 10 as $x | foreach .[] as $y (0; . + $y + f)", "[1, 2]",
    ),
    content=[11, 23],
  )
}

///|
test "coverage: function call validates argument count" {
  assert_true(
    (try? coverage_eval("def add(a; b): a + b; add(1)", "null")) is Err(_),
  )
}

///|
test "coverage: undefined function errors" {
  assert_true((try? coverage_eval("no_such_fn", "null")) is Err(_))
}
