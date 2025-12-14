///|
fn cov_eval6(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  eval(expr, json_input).collect()
}

///|
test "coverage: foreach extract empty falls back to accumulator" {
  @json.inspect(cov_eval6("foreach .[] as $x (0; . + $x; empty)", "[1, 2]"), content=[
    1, 3,
  ])
}

///|
test "coverage: scan has misses and type mismatch" {
  @json.inspect(cov_eval6("scan(\"aa\")", "\"abaaa\""), content=["aa"])
  assert_true((try? cov_eval6("scan(\"a\")", "1")) is Err(_))
}

///|
test "coverage: compare_json remaining base cases" {
  @json.inspect(cov_eval6("1 > null", "null"), content=[true])
  @json.inspect(cov_eval6("false < false", "null"), content=[false])
  @json.inspect(cov_eval6("true < true", "null"), content=[false])
}

///|
test "coverage: and/or truthiness behavior" {
  @json.inspect(cov_eval6("false and 1", "null"), content=[false])
  @json.inspect(cov_eval6("null and 1", "null"), content=[false])
  @json.inspect(cov_eval6("1 and 2", "null"), content=[2])
  @json.inspect(cov_eval6("false or 2", "null"), content=[2])
  @json.inspect(cov_eval6("null or 2", "null"), content=[2])
  @json.inspect(cov_eval6("1 or 2", "null"), content=[1])
}

///|
test "coverage: delpaths and setpath edge cases" {
  @json.inspect(cov_eval6("delpaths([[]])", "[1]"), content=[null])
  @json.inspect(cov_eval6("delpaths([[\"a\"]])", "[1]"), content=[[1]])
  @json.inspect(cov_eval6("delpaths([[10]])", "[1]"), content=[[1]])
  @json.inspect(cov_eval6("delpaths([[1, 0]])", "[1]"), content=[[1]])
  @json.inspect(cov_eval6("setpath([\"a\"]; 1)", "[0]"), content=[[0]])
}

///|
test "coverage: modulo rejects non-numbers" {
  assert_true((try? cov_eval6("null % 2", "null")) is Err(_))
}
