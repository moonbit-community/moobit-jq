///|
fn cov_eval9(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  @ast.eval(expr, json_input).collect()
}

///|
test "coverage: map and min/max edge cases" {
  assert_true((try? cov_eval9("map(.)", "1")) is Err(_))
  @json.inspect(cov_eval9("min", "[]"), content=[null])
  @json.inspect(cov_eval9("max", "[]"), content=[null])
}

///|
test "coverage: control flow fallbacks" {
  @json.inspect(cov_eval9("if empty then 1 else 2 end", "null"), content=[2])
  @json.inspect(cov_eval9("try (1 / 0)", "null"), content=[])
  @json.inspect(cov_eval9("empty // 2", "null"), content=[2])
}

///|
test "coverage: undefined variable" {
  assert_true((try? cov_eval9("$missing", "null")) is Err(_))
}

///|
test "coverage: format errors" {
  assert_true((try? cov_eval9("@base64", "1")) is Err(_))
  assert_true((try? cov_eval9("@base64d", "1")) is Err(_))
  assert_true((try? cov_eval9("@csv", "1")) is Err(_))
  assert_true((try? cov_eval9("@html", "1")) is Err(_))
  assert_true((try? cov_eval9("@wat", "\"x\"")) is Err(_))
}

///|
test "coverage: function argument handling" {
  assert_true(
    (try? cov_eval9("def add(x; y): $x + $y; add(1)", "null")) is Err(_),
  )
  @json.inspect(cov_eval9("def id(x): $x; id(empty)", "null"), content=[null])
}

///|
test "coverage: reduce and assignment edges" {
  @json.inspect(
    cov_eval9("reduce .[] as $x (empty; . + $x)", "[1, 2]"),
    content=[null],
  )
  @json.inspect(cov_eval9(".a = empty", "{\"a\": 1}"), content=[{ "a": 1 }])
}

///|
test "coverage: update operator branches" {
  @json.inspect(cov_eval9(". |= empty", "1"), content=[1])
  @json.inspect(cov_eval9(". |= 2", "1"), content=[2])
  @json.inspect(cov_eval9(".a |= empty", "{\"a\": 1}"), content=[{ "a": 1 }])
  @json.inspect(cov_eval9(".a |= . + 1", "1"), content=[1])
  @json.inspect(cov_eval9(".[] |= .", "[1, 2]"), content=[[1, 2]])
  @json.inspect(
    cov_eval9(".a[10] |= . + 1", "{\"a\": [1]}"),
    content=[{ "a": [1] }],
  )
  @json.inspect(
    cov_eval9(".foo.bar |= . + 1", "{\"foo\": {\"bar\": 1}}"),
    content=[{ "foo": { "bar": 2 } }],
  )
  @json.inspect(
    cov_eval9(".foo[0] |= . + 1", "{\"foo\": [1]}"),
    content=[{ "foo": [2] }],
  )
}

///|
test "coverage: walk empty results and recurse safety" {
  @json.inspect(cov_eval9("walk(empty)", "[1, 2]"), content=[[1, 2]])
  @json.inspect(cov_eval9("walk(empty)", "{\"a\": 1}"), content=[{ "a": 1 }])
  @json.inspect(cov_eval9("walk(empty)", "1"), content=[1])
  let nums : Array[String] = []
  for i = 0; i <= 100; i = i + 1 {
    nums.push(i.to_string())
  }
  let sep = ","
  let input = "[\{nums.join(sep)}]"
  let results = cov_eval9("recurse(.[]; . != null)", input)
  inspect(results.length(), content="102")
}

///|
test "coverage: numeric builtins mismatches" {
  assert_true((try? cov_eval9("round", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("ceil", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("abs", "\"x\"")) is Err(_))
}

///|
test "coverage: string builtins mismatches" {
  assert_true((try? cov_eval9("startswith(\"a\")", "1")) is Err(_))
  assert_true((try? cov_eval9("endswith(\"a\")", "1")) is Err(_))
  assert_true((try? cov_eval9("split(\",\")", "1")) is Err(_))
  assert_true((try? cov_eval9("join(\",\")", "1")) is Err(_))
  @json.inspect(
    cov_eval9("join(\",\")", "[1, \"a\"]"),
    content=["Number(1),a"],
  )
  @json.inspect(cov_eval9("contains(empty)", "\"abc\""), content=[false])
  assert_true((try? cov_eval9("ltrimstr(\"a\")", "1")) is Err(_))
  assert_true((try? cov_eval9("rtrimstr(\"a\")", "1")) is Err(_))
  assert_true((try? cov_eval9("ascii_upcase", "1")) is Err(_))
  assert_true((try? cov_eval9("ascii_downcase", "1")) is Err(_))
}

///|
test "coverage: ordering helper mismatches" {
  assert_true((try? cov_eval9("sort_by(.)", "1")) is Err(_))
  assert_true((try? cov_eval9("group_by(.)", "1")) is Err(_))
}

///|
test "coverage: index helpers edge cases" {
  @json.inspect(cov_eval9("indices(empty)", "[1, 2]"), content=[[]])
  @json.inspect(cov_eval9("indices(1)", "\"abc\""), content=[[]])
  assert_true((try? cov_eval9("indices(1)", "{}")) is Err(_))
  @json.inspect(cov_eval9("index(empty)", "[1, 2]"), content=[null])
  @json.inspect(cov_eval9("index(\"z\")", "\"abc\""), content=[null])
  @json.inspect(cov_eval9("index(1)", "\"abc\""), content=[null])
  assert_true((try? cov_eval9("index(1)", "{}")) is Err(_))
  @json.inspect(cov_eval9("nth(5)", "[1]"), content=[])
  assert_true((try? cov_eval9("nth(1)", "1")) is Err(_))
  @json.inspect(cov_eval9("rindex(empty)", "[1]"), content=[null])
  @json.inspect(cov_eval9("rindex(9)", "[1, 2]"), content=[null])
  @json.inspect(cov_eval9("rindex(\"z\")", "\"abc\""), content=[null])
  @json.inspect(cov_eval9("rindex(1)", "\"abc\""), content=[null])
  assert_true((try? cov_eval9("rindex(1)", "{}")) is Err(_))
}

///|
test "coverage: math and range edges" {
  @json.inspect(cov_eval9("pow(empty)", "2"), content=[null])
  assert_true((try? cov_eval9("pow(2)", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("log", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("exp", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("sin", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("cos", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("tan", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("asin", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("acos", "\"x\"")) is Err(_))
  assert_true((try? cov_eval9("atan", "\"x\"")) is Err(_))
  @json.inspect(cov_eval9("range(empty; 3)", "null"), content=[])
  @json.inspect(cov_eval9("range(1; 3; empty)", "null"), content=[])
  assert_true((try? cov_eval9("range(1; \"x\")", "null")) is Err(_))
}

///|
test "coverage: iterator helpers and path edges" {
  @json.inspect(cov_eval9("first", "[]"), content=[])
  @json.inspect(cov_eval9("last", "[]"), content=[])
  assert_true((try? cov_eval9("first", "1")) is Err(_))
  assert_true((try? cov_eval9("last", "1")) is Err(_))
  assert_true((try? cov_eval9("any", "1")) is Err(_))
  assert_true((try? cov_eval9("all", "1")) is Err(_))
  @json.inspect(cov_eval9(". >= 1", "1"), content=[true])
  @json.inspect(cov_eval9(". < []", "false"), content=[false])
  @json.inspect(cov_eval9("flatten(0)", "[1, [2]]"), content=[[1, [2]]])
  @json.inspect(cov_eval9("setpath([]; 1)", "{\"a\": 1}"), content=[1])
  @json.inspect(
    cov_eval9("setpath([{}]; 1)", "{\"a\": 1}"),
    content=[{ "a": 1 }],
  )
}

///|
test "coverage: from_entries edge cases" {
  let input = "[{\"key\":\"a\"},{\"key\":1},{\"key\":{}},{\"value\":1},1]"
  @json.inspect(cov_eval9("from_entries", input), content=[{}])
  assert_true((try? cov_eval9("from_entries", "1")) is Err(_))
  assert_true((try? cov_eval9("with_entries(.)", "1")) is Err(_))
}
