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
  @json.inspect(coverage_eval("setpath([{}]; 1)", "{\"a\": 1}"), content=[
    { "a": 1 },
  ])
}

///|
test "coverage: parse_slice_part handles spaced negative index" {
  // Cover parser branch where '-' is tokenized separately from the number.
  @json.inspect(coverage_eval(".[- 1]", "[10, 20, 30]"), content=[30])
}
