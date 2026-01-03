///|
test "coverage: null/bool comparisons" {
  @json.inspect(coverage_eval("null < null", "null"), content=[false])
  @json.inspect(coverage_eval("null < false", "null"), content=[true])
  @json.inspect(coverage_eval("false < true", "null"), content=[true])
  @json.inspect(coverage_eval("true > false", "null"), content=[true])
}

///|
test "coverage: contains/inside/has on arrays and objects" {
  @json.inspect(coverage_eval("contains(2)", "[1, 2, 3]"), content=[true])
  @json.inspect(coverage_eval("contains(\"a\")", "{\"a\": 1}"), content=[true])
  @json.inspect(coverage_eval("\"a\" | inside({\"a\": 1})", "null"), content=[true])
  @json.inspect(coverage_eval("[1, 2] | inside([2, 1, 3])", "null"), content=[true])
  @json.inspect(coverage_eval("[1, 9] | inside([2, 1, 3])", "null"), content=[false])
  @json.inspect(coverage_eval("has(\"1\")", "[10, 20]"), content=[true])
  @json.inspect(coverage_eval("has(\"-1\")", "[10, 20]"), content=[true])
  @json.inspect(coverage_eval("has(\"2\")", "[10, 20]"), content=[false])
  @json.inspect(coverage_eval("has(\"x\")", "[10, 20]"), content=[false])
}

///|
test "coverage: update path navigates through arrays" {
  let input : String =
    #|{
    #|  "a": [1]
    #|}
  @json.inspect(coverage_eval(".a[0] |= . + 1", input), content=[{ "a": [2] }])
}

///|
test "coverage: unique_by/min_by/max_by" {
  let input = "[{\"x\":1},{\"x\":1},{\"x\":2}]"
  @json.inspect(coverage_eval("unique_by(.x)", input), content=[
    [{ "x": 1 }, { "x": 2 }],
  ])
  @json.inspect(coverage_eval("min_by(.x)", input), content=[{ "x": 1 }])
  @json.inspect(coverage_eval("max_by(.x)", input), content=[{ "x": 2 }])
}

///|
test "coverage: combinations and transpose" {
  @json.inspect(coverage_eval("combinations", "[[1,2],[3,4]]"), content=[
    [1, 3],
    [1, 4],
    [2, 3],
    [2, 4],
  ])
  @json.inspect(coverage_eval("combinations", "[[1], 2]"), content=[])
  @json.inspect(coverage_eval("transpose", "[[1,2,3],[4,5]]"), content=[
    [[1, 4], [2, 5], [3]],
  ])
}

///|
test "coverage: arithmetic array subtraction and string repetition" {
  @json.inspect(coverage_eval("[1,2,3] - [2]", "null"), content=[[1, 3]])
  @json.inspect(coverage_eval("\"ab\" * 3", "null"), content=["ababab"])
  @json.inspect(coverage_eval("3 * \"ab\"", "null"), content=["ababab"])
}

///|
test "coverage: more string search helpers" {
  @json.inspect(coverage_eval("index(\"foo\")", "\"foobar\""), content=[0])
  @json.inspect(coverage_eval("indices(\"o\")", "\"foobar\""), content=[[]])
}

///|
test "coverage: flatten() parses and runs" {
  @json.inspect(coverage_eval("flatten()", "[1, [2]]"), content=[[1, 2]])
}

///|
test "coverage: @html escapes ampersand and quotes" {
  @json.inspect(coverage_eval("@html", "\"&\\\"'\""), content=["&amp;&quot;&#39;"])
}

///|
test "coverage: math functions" {
  @json.inspect(coverage_eval("pow(3)", "2"), content=[8])
  @json.inspect(coverage_eval("log", "1"), content=[0])
  @json.inspect(coverage_eval("exp", "0"), content=[1])
  @json.inspect(coverage_eval("sin", "0"), content=[0])
  @json.inspect(coverage_eval("cos", "0"), content=[1])
  @json.inspect(coverage_eval("tan", "0"), content=[0])
  @json.inspect(coverage_eval("asin", "0"), content=[0])
  @json.inspect(coverage_eval("acos", "1"), content=[0])
  @json.inspect(coverage_eval("atan", "0"), content=[0])
  assert_true((try? coverage_eval("sin", "\"x\"")) is Err(_))
}

///|
test "coverage: base64 padding and decode edge cases" {
  @json.inspect(coverage_eval("@base64", "\"A\""), content=["QQ=="])
  @json.inspect(coverage_eval("@base64", "\"AB\""), content=["QUI="])
  // Exercise '+' and '/' decode table and fail at UTF-8 decoding.
  assert_true((try? coverage_eval("@base64d", "\"++//\"")) is Err(_))
  // Invalid padding sequence.
  assert_true((try? coverage_eval("@base64d", "\"AA=A\"")) is Err(_))
}
