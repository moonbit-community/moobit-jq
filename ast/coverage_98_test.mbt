///|
test "coverage: update operator deep branches" {
  json_inspect(coverage_eval(".[0] |= . + 1", "{\"a\":1}"), content=[{ "a": 1 }])
  json_inspect(coverage_eval(".a.b |= . + 1", "{}"), content=[{ "a": null }])
  json_inspect(coverage_eval(".a.b |= . + 1", "1"), content=[1])
  json_inspect(
    coverage_eval("(.foo | .bar) |= . + 1", "{\"foo\":{\"bar\":1}}"),
    content=[{ "foo": { "bar": 2 } }],
  )
  json_inspect(coverage_eval("(empty | .bar) |= . + 1", "{\"bar\":1}"), content=[
    { "bar": 1 },
  ])
  json_inspect(coverage_eval("length |= empty", "{\"a\":1}"), content=[
    { "a": 1 },
  ])
  json_inspect(coverage_eval("length |= 3", "[1,2]"), content=[3])
  json_inspect(coverage_eval("empty |= 1", "{\"a\":1}"), content=[{ "a": 1 }])
}

///|
test "coverage: contains, inside, has, in fallbacks" {
  json_inspect(coverage_eval("contains(\"a\")", "1"), content=[false])
  json_inspect(coverage_eval("inside(empty)", "\"a\""), content=[false])
  json_inspect(coverage_eval("inside(\"abc\")", "\"b\""), content=[true])
  json_inspect(coverage_eval("inside(\"abc\")", "1"), content=[false])
  json_inspect(coverage_eval("has(\"a\")", "1"), content=[false])
  json_inspect(coverage_eval("in(empty)", "\"a\""), content=[false])
  json_inspect(coverage_eval("in({\"a\":1})", "1"), content=[false])
  json_inspect(coverage_eval("in([1,2])", "\"a\""), content=[false])
  json_inspect(coverage_eval("in(1)", "\"a\""), content=[false])
}

///|
test "coverage: getpath, while, delpaths edges" {
  json_inspect(coverage_eval("getpath([1])", "[0]"), content=[null])
  json_inspect(coverage_eval("while(. < 2; empty)", "1"), content=[1])
  json_inspect(coverage_eval("delpaths([[1,2]])", "\"x\""), content=["x"])
}

///|
test "coverage: builtin mismatch errors" {
  assert_true((try? coverage_eval("to_entries", "1")) is Err(_))
  assert_true((try? coverage_eval("map_values(.)", "1")) is Err(_))
  assert_true((try? coverage_eval("unique_by(.)", "1")) is Err(_))
  assert_true((try? coverage_eval("transpose", "1")) is Err(_))
  assert_true((try? coverage_eval("range(1; \"x\"; 1)", "null")) is Err(_))
  assert_true((try? coverage_eval("1 % 0", "null")) is Err(_))
}

///|
test "coverage: foreach, min_by, transpose, implode" {
  json_inspect(coverage_eval("foreach .[] as $x (empty; . + $x)", "[1, 2]"), content=[])
  json_inspect(coverage_eval("min_by(.)", "[2, 1]"), content=[1])
  json_inspect(coverage_eval("transpose", "[[1], 2]"), content=[[[1]]])
  json_inspect(coverage_eval("implode", "[97, \"x\"]"), content=["a"])
}
