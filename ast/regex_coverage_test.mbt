///|
fn regex_eval(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  eval(expr, json_input).collect()
}

///|
test "coverage: test(pattern) returns boolean" {
  @json.inspect(regex_eval("test(\"foo\")", "\"foobar\""), content=[true])
  @json.inspect(regex_eval("test(\"baz\")", "\"foobar\""), content=[false])
}

///|
test "coverage: match(pattern) returns match object or empty" {
  @json.inspect(regex_eval("match(\"foo\")", "\"foobar\""), content=[
    {
      "match": "foo",
      "offset": 0,
      "length": 3,
      "string": "foobar",
      "captures": [],
    },
  ])
  @json.inspect(regex_eval("match(\"zzz\")", "\"foobar\""), content=[])
}

///|
test "coverage: capture(pattern) returns object" {
  @json.inspect(regex_eval("capture(\"foo\")", "\"foobar\""), content=[{}])
}

///|
test "coverage: splits(pattern) yields segments" {
  @json.inspect(regex_eval("splits(\"-\")", "\"a-b-c\""), content=[
    "a", "b", "c",
  ])
}

///|
test "coverage: sub/gsub replace text" {
  @json.inspect(regex_eval("sub(\"world\"; \"moon\")", "\"hello world\""), content=[
    "hello moon",
  ])
  @json.inspect(regex_eval("gsub(\"a\"; \"b\")", "\"a a a\""), content=["b b b"])
}

///|
test "coverage: regex functions reject non-string input" {
  assert_true((try? regex_eval("test(\"x\")", "1")) is Err(_))
  assert_true((try? regex_eval("match(\"x\")", "1")) is Err(_))
  assert_true((try? regex_eval("capture(\"x\")", "1")) is Err(_))
  assert_true((try? regex_eval("splits(\"x\")", "1")) is Err(_))
  assert_true((try? regex_eval("sub(\"x\"; \"y\")", "1")) is Err(_))
  assert_true((try? regex_eval("gsub(\"x\"; \"y\")", "1")) is Err(_))
}
