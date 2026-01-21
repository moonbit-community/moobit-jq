///|
/// jq-compat tests for @uri

///|
test "jq compat: @uri encodes spaces as %20" {
  let results = coverage_eval("@uri", "\"a b\"")
  json_inspect(results, content=["a%20b"])
}

///|
test "jq compat: @uri encodes slash" {
  let results = coverage_eval("@uri", "\"a/b\"")
  json_inspect(results, content=["a%2Fb"])
}

///|
test "jq compat: @uri keeps unreserved characters" {
  let results = coverage_eval("@uri", "\"-_.~\"")
  json_inspect(results, content=["-_.~"])
}

///|
test "jq compat: @uri percent-encodes reserved punctuation" {
  json_inspect(coverage_eval("@uri", "\"!\""), content=["%21"])
  json_inspect(coverage_eval("@uri", "\"%\""), content=["%25"])
}

///|
test "jq compat: @uri percent-encodes utf8 bytes" {
  json_inspect(coverage_eval("@uri", "\"中文\""), content=[
    "%E4%B8%AD%E6%96%87",
  ])
  json_inspect(coverage_eval("@uri", "\"ÿ\""), content=["%C3%BF"])
}

///|
test "jq compat: @uri rejects non-string input" {
  let result = try? coverage_eval("@uri", "1")
  assert_true(result is Err(_))
}
