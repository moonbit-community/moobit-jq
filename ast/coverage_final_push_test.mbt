///|
test "coverage: foreach extract empty falls back to accumulator" {
  @json.inspect(
    coverage_eval("foreach .[] as $x (0; . + $x; empty)", "[1, 2]"),
    content=[1, 3],
  )
}

///|
test "coverage: scan has misses and type mismatch" {
  @json.inspect(coverage_eval("scan(\"aa\")", "\"abaaa\""), content=["aa"])
  assert_true((try? coverage_eval("scan(\"a\")", "1")) is Err(_))
}

///|
test "coverage: scan skips invalid slice boundaries" {
  let emoji = @encoding/utf8.decode([0xf0, 0x9f, 0x98, 0x80])
  let input = "\"\{emoji}a\""
  @json.inspect(coverage_eval("scan(\"a\")", input), content=["a"])
}

///|
test "coverage: compare_json remaining base cases" {
  @json.inspect(coverage_eval("1 > null", "null"), content=[true])
  @json.inspect(coverage_eval("false < false", "null"), content=[false])
  @json.inspect(coverage_eval("true < true", "null"), content=[false])
}

///|
test "coverage: and/or truthiness behavior" {
  @json.inspect(coverage_eval("false and 1", "null"), content=[false])
  @json.inspect(coverage_eval("null and 1", "null"), content=[false])
  @json.inspect(coverage_eval("1 and 2", "null"), content=[2])
  @json.inspect(coverage_eval("false or 2", "null"), content=[2])
  @json.inspect(coverage_eval("null or 2", "null"), content=[2])
  @json.inspect(coverage_eval("1 or 2", "null"), content=[1])
}

///|
test "coverage: delpaths and setpath edge cases" {
  @json.inspect(coverage_eval("delpaths([[]])", "[1]"), content=[null])
  @json.inspect(coverage_eval("delpaths([[\"a\"]])", "[1]"), content=[[1]])
  @json.inspect(coverage_eval("delpaths([[10]])", "[1]"), content=[[1]])
  @json.inspect(coverage_eval("delpaths([[1, 0]])", "[1]"), content=[[1]])
  @json.inspect(coverage_eval("setpath([\"a\"]; 1)", "[0]"), content=[[0]])
}

///|
test "coverage: modulo rejects non-numbers" {
  assert_true((try? coverage_eval("null % 2", "null")) is Err(_))
}
