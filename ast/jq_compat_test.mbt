///|
/// jq-compat tests based on jq(1) behavior.
fn jq_eval(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input)
  eval(expr, json_input).collect()
}

///|
test "jq compat: @uri encodes spaces as %20" {
  let results = jq_eval("@uri", "\"a b\"")
  @json.inspect(results, content=["a%20b"])
}

///|
test "jq compat: @uri encodes slash" {
  let results = jq_eval("@uri", "\"a/b\"")
  @json.inspect(results, content=["a%2Fb"])
}

///|
test "jq compat: @uri keeps unreserved characters" {
  let results = jq_eval("@uri", "\"-_.~\"")
  @json.inspect(results, content=["-_.~"])
}

///|
test "jq compat: @uri percent-encodes reserved punctuation" {
  @json.inspect(jq_eval("@uri", "\"!\""), content=["%21"])
  @json.inspect(jq_eval("@uri", "\"%\""), content=["%25"])
}

///|
test "jq compat: @uri percent-encodes utf8 bytes" {
  @json.inspect(jq_eval("@uri", "\"中文\""), content=["%E4%B8%AD%E6%96%87"])
  @json.inspect(jq_eval("@uri", "\"ÿ\""), content=["%C3%BF"])
}

///|
test "jq compat: @uri rejects non-string input" {
  let result = try? jq_eval("@uri", "1")
  assert_true(result is Err(_))
}

///|
test "jq compat: @base64 encodes utf8" {
  let results = jq_eval("@base64", "\"中文\"")
  @json.inspect(results, content=["5Lit5paH"])
}

///|
test "jq compat: @base64d decodes utf8" {
  let results = jq_eval("@base64d", "\"5Lit5paH\"")
  @json.inspect(results, content=["中文"])
}

///|
test "jq compat: @base64d rejects invalid base64" {
  let result = try? jq_eval("@base64d", "\"***\"")
  assert_true(result is Err(_))
}

///|
test "jq compat: split keeps empty segments" {
  let results = jq_eval("split(\"/\")", "\"a/b//c/\"")
  @json.inspect(results, content=[["a", "b", "", "c", ""]])
}

///|
test "jq compat: ltrimstr removes prefix only" {
  @json.inspect(jq_eval("ltrimstr(\"foo\")", "\"foobar\""), content=["bar"])
  @json.inspect(jq_eval("ltrimstr(\"bar\")", "\"foobar\""), content=["foobar"])
}

///|
test "jq compat: rtrimstr removes suffix only" {
  @json.inspect(jq_eval("rtrimstr(\"bar\")", "\"foobar\""), content=["foo"])
  @json.inspect(jq_eval("rtrimstr(\"baz\")", "\"foobar\""), content=["foobar"])
}

///|
test "jq compat: ascii_upcase/downcase only affects ASCII" {
  @json.inspect(jq_eval("ascii_downcase", "\"AbÇ\""), content=["abÇ"])
  @json.inspect(jq_eval("ascii_upcase", "\"AbÇ\""), content=["ABÇ"])
}

///|
test "jq compat: paths order matches jq" {
  let input : String =
    #|{
    #|  "a": [1, 2],
    #|  "b": { "c": 3 }
    #|}
  let results = jq_eval("paths", input)
  @json.inspect(results, content=[["a"], ["a", 0], ["a", 1], ["b"], ["b", "c"]])
}
