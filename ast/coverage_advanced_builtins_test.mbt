///|
fn cov_eval3(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  eval(expr, json_input).collect()
}

///|
test "coverage: null/bool comparisons" {
  @json.inspect(cov_eval3("null < null", "null"), content=[false])
  @json.inspect(cov_eval3("null < false", "null"), content=[true])
  @json.inspect(cov_eval3("false < true", "null"), content=[true])
  @json.inspect(cov_eval3("true > false", "null"), content=[true])
}

///|
test "coverage: contains/inside/has on arrays and objects" {
  @json.inspect(cov_eval3("contains(2)", "[1, 2, 3]"), content=[true])
  @json.inspect(cov_eval3("contains(\"a\")", "{\"a\": 1}"), content=[true])
  @json.inspect(cov_eval3("\"a\" | inside({\"a\": 1})", "null"), content=[true])
  @json.inspect(cov_eval3("[1, 2] | inside([2, 1, 3])", "null"), content=[true])
  @json.inspect(cov_eval3("[1, 9] | inside([2, 1, 3])", "null"), content=[false])
  @json.inspect(cov_eval3("has(\"1\")", "[10, 20]"), content=[true])
  @json.inspect(cov_eval3("has(\"-1\")", "[10, 20]"), content=[true])
  @json.inspect(cov_eval3("has(\"2\")", "[10, 20]"), content=[false])
  @json.inspect(cov_eval3("has(\"x\")", "[10, 20]"), content=[false])
}

///|
test "coverage: update path navigates through arrays" {
  let input : String =
    #|{
    #|  "a": [1]
    #|}
  @json.inspect(cov_eval3(".a[0] |= . + 1", input), content=[{ "a": [2] }])
}

///|
test "coverage: unique_by/min_by/max_by" {
  let input = "[{\"x\":1},{\"x\":1},{\"x\":2}]"
  @json.inspect(cov_eval3("unique_by(.x)", input), content=[
    [{ "x": 1 }, { "x": 2 }],
  ])
  @json.inspect(cov_eval3("min_by(.x)", input), content=[{ "x": 1 }])
  @json.inspect(cov_eval3("max_by(.x)", input), content=[{ "x": 2 }])
}

///|
test "coverage: combinations and transpose" {
  @json.inspect(cov_eval3("combinations", "[[1,2],[3,4]]"), content=[
    [1, 3],
    [1, 4],
    [2, 3],
    [2, 4],
  ])
  @json.inspect(cov_eval3("combinations", "[[1], 2]"), content=[])
  @json.inspect(cov_eval3("transpose", "[[1,2,3],[4,5]]"), content=[
    [[1, 4], [2, 5], [3]],
  ])
}

///|
test "coverage: arithmetic array subtraction and string repetition" {
  @json.inspect(cov_eval3("[1,2,3] - [2]", "null"), content=[[1, 3]])
  @json.inspect(cov_eval3("\"ab\" * 3", "null"), content=["ababab"])
  @json.inspect(cov_eval3("3 * \"ab\"", "null"), content=["ababab"])
}

///|
test "coverage: more string search helpers" {
  @json.inspect(cov_eval3("index(\"foo\")", "\"foobar\""), content=[0])
  @json.inspect(cov_eval3("indices(\"o\")", "\"foobar\""), content=[[]])
}

///|
test "coverage: flatten() parses and runs" {
  @json.inspect(cov_eval3("flatten()", "[1, [2]]"), content=[[1, 2]])
}

///|
test "coverage: @html escapes ampersand and quotes" {
  @json.inspect(cov_eval3("@html", "\"&\\\"'\""), content=["&amp;&quot;&#39;"])
}

///|
test "coverage: math functions" {
  @json.inspect(cov_eval3("pow(3)", "2"), content=[8])
  @json.inspect(cov_eval3("log", "1"), content=[0])
  @json.inspect(cov_eval3("exp", "0"), content=[1])
  @json.inspect(cov_eval3("sin", "0"), content=[0])
  @json.inspect(cov_eval3("cos", "0"), content=[1])
  @json.inspect(cov_eval3("tan", "0"), content=[0])
  @json.inspect(cov_eval3("asin", "0"), content=[0])
  @json.inspect(cov_eval3("acos", "1"), content=[0])
  @json.inspect(cov_eval3("atan", "0"), content=[0])
  assert_true((try? cov_eval3("sin", "\"x\"")) is Err(_))
}

///|
test "coverage: base64 padding and decode edge cases" {
  @json.inspect(cov_eval3("@base64", "\"A\""), content=["QQ=="])
  @json.inspect(cov_eval3("@base64", "\"AB\""), content=["QUI="])
  // Exercise '+' and '/' decode table and fail at UTF-8 decoding.
  assert_true((try? cov_eval3("@base64d", "\"++//\"")) is Err(_))
  // Invalid padding sequence.
  assert_true((try? cov_eval3("@base64d", "\"AA=A\"")) is Err(_))
}
