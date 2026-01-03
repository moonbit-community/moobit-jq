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
test "coverage: format errors" {
  assert_true((try? coverage_eval("@base64", "1")) is Err(_))
  assert_true((try? coverage_eval("@base64d", "1")) is Err(_))
  assert_true((try? coverage_eval("@csv", "1")) is Err(_))
  assert_true((try? coverage_eval("@html", "1")) is Err(_))
  assert_true((try? coverage_eval("@wat", "\"x\"")) is Err(_))
}

///|
test "coverage: function argument handling" {
  assert_true(
    (try? coverage_eval("def f(x; y): $x + $y; f(1)", "null")) is Err(_),
  )
  @json.inspect(coverage_eval("def id(x): $x; id(empty)", "null"), content=[null])
}

///|
test "coverage: reduce and assignment edges" {
  @json.inspect(
    coverage_eval("reduce .[] as $x (empty; . + $x)", "[1, 2]"),
    content=[null],
  )
  @json.inspect(coverage_eval(".a = empty", "{\"a\": 1}"), content=[{ "a": 1 }])
}

///|
test "coverage: update operator branches" {
  @json.inspect(coverage_eval(". |= empty", "1"), content=[1])
  @json.inspect(coverage_eval(". |= 2", "1"), content=[2])
  @json.inspect(coverage_eval(".a |= empty", "{\"a\": 1}"), content=[{ "a": 1 }])
  @json.inspect(coverage_eval(".a |= . + 1", "1"), content=[1])
  @json.inspect(coverage_eval(".[] |= .", "[1, 2]"), content=[[1, 2]])
  @json.inspect(
    coverage_eval(".a[10] |= . + 1", "{\"a\": [1]}"),
    content=[{ "a": [1] }],
  )
  @json.inspect(
    coverage_eval(".foo.bar |= . + 1", "{\"foo\": {\"bar\": 1}}"),
    content=[{ "foo": { "bar": 2 } }],
  )
  @json.inspect(
    coverage_eval(".foo[0] |= . + 1", "{\"foo\": [1]}"),
    content=[{ "foo": [2] }],
  )
}

///|
test "coverage: walk empty results and recurse safety" {
  @json.inspect(coverage_eval("walk(empty)", "[1, 2]"), content=[[1, 2]])
  @json.inspect(coverage_eval("walk(empty)", "{\"a\": 1}"), content=[{ "a": 1 }])
  @json.inspect(coverage_eval("walk(empty)", "1"), content=[1])
  let nums : Array[String] = []
  for i = 0; i <= 100; i = i + 1 {
    nums.push(i.to_string())
  }
  let sep = ","
  let input = "[\{nums.join(sep)}]"
  let results = coverage_eval("recurse(.[]; . != null)", input)
  inspect(results.length(), content="102")
}

///|
test "coverage: numeric builtins mismatches" {
  assert_true((try? coverage_eval("round", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("ceil", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("abs", "\"x\"")) is Err(_))
}

///|
test "coverage: string builtins mismatches" {
  assert_true((try? coverage_eval("startswith(\"a\")", "1")) is Err(_))
  assert_true((try? coverage_eval("endswith(\"a\")", "1")) is Err(_))
  assert_true((try? coverage_eval("split(\",\")", "1")) is Err(_))
  assert_true((try? coverage_eval("join(\",\")", "1")) is Err(_))
  @json.inspect(
    coverage_eval("join(\",\")", "[1, \"a\"]"),
    content=["Number(1),a"],
  )
  @json.inspect(coverage_eval("contains(empty)", "\"abc\""), content=[false])
  assert_true((try? coverage_eval("ltrimstr(\"a\")", "1")) is Err(_))
  assert_true((try? coverage_eval("rtrimstr(\"a\")", "1")) is Err(_))
  assert_true((try? coverage_eval("ascii_upcase", "1")) is Err(_))
  assert_true((try? coverage_eval("ascii_downcase", "1")) is Err(_))
}

///|
test "coverage: ordering helper mismatches" {
  assert_true((try? coverage_eval("sort_by(.)", "1")) is Err(_))
  assert_true((try? coverage_eval("group_by(.)", "1")) is Err(_))
}

///|
test "coverage: index helpers edge cases" {
  @json.inspect(coverage_eval("indices(empty)", "[1, 2]"), content=[[]])
  @json.inspect(coverage_eval("indices(1)", "\"abc\""), content=[[]])
  assert_true((try? coverage_eval("indices(1)", "{}")) is Err(_))
  @json.inspect(coverage_eval("index(empty)", "[1, 2]"), content=[null])
  @json.inspect(coverage_eval("index(\"z\")", "\"abc\""), content=[null])
  @json.inspect(coverage_eval("index(1)", "\"abc\""), content=[null])
  assert_true((try? coverage_eval("index(1)", "{}")) is Err(_))
  @json.inspect(coverage_eval("nth(5)", "[1]"), content=[])
  assert_true((try? coverage_eval("nth(1)", "1")) is Err(_))
  @json.inspect(coverage_eval("rindex(empty)", "[1]"), content=[null])
  @json.inspect(coverage_eval("rindex(9)", "[1, 2]"), content=[null])
  @json.inspect(coverage_eval("rindex(\"z\")", "\"abc\""), content=[null])
  @json.inspect(coverage_eval("rindex(1)", "\"abc\""), content=[null])
  assert_true((try? coverage_eval("rindex(1)", "{}")) is Err(_))
}

///|
test "coverage: math and range edges" {
  @json.inspect(coverage_eval("pow(empty)", "2"), content=[null])
  assert_true((try? coverage_eval("pow(2)", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("log", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("exp", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("sin", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("cos", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("tan", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("asin", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("acos", "\"x\"")) is Err(_))
  assert_true((try? coverage_eval("atan", "\"x\"")) is Err(_))
  @json.inspect(coverage_eval("range(empty; 3)", "null"), content=[])
  @json.inspect(coverage_eval("range(1; 3; empty)", "null"), content=[])
  assert_true((try? coverage_eval("range(1; \"x\")", "null")) is Err(_))
}

///|
test "coverage: iterator helpers and path edges" {
  @json.inspect(coverage_eval("first", "[]"), content=[])
  @json.inspect(coverage_eval("last", "[]"), content=[])
  assert_true((try? coverage_eval("first", "1")) is Err(_))
  assert_true((try? coverage_eval("last", "1")) is Err(_))
  assert_true((try? coverage_eval("any", "1")) is Err(_))
  assert_true((try? coverage_eval("all", "1")) is Err(_))
  @json.inspect(coverage_eval(". >= 1", "1"), content=[true])
  @json.inspect(coverage_eval(". < []", "false"), content=[false])
  @json.inspect(coverage_eval("flatten(0)", "[1, [2]]"), content=[[1, [2]]])
  @json.inspect(coverage_eval("setpath([]; 1)", "{\"a\": 1}"), content=[1])
  @json.inspect(
    coverage_eval("setpath([{}]; 1)", "{\"a\": 1}"),
    content=[{ "a": 1 }],
  )
}

///|
test "coverage: from_entries edge cases" {
  let input = "[{\"key\":\"a\"},{\"key\":1},{\"key\":{}},{\"value\":1},1]"
  @json.inspect(coverage_eval("from_entries", input), content=[{}])
  assert_true((try? coverage_eval("from_entries", "1")) is Err(_))
  assert_true((try? coverage_eval("with_entries(.)", "1")) is Err(_))
}
