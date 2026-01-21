///|
/// jq-compat tests for @base64 and @base64d

///|
test "jq compat: @base64 encodes utf8" {
  let results = coverage_eval("@base64", "\"中文\"")
  json_inspect(results, content=["5Lit5paH"])
}

///|
test "jq compat: @base64d decodes utf8" {
  let results = coverage_eval("@base64d", "\"5Lit5paH\"")
  json_inspect(results, content=["中文"])
}

///|
test "jq compat: @base64d rejects invalid base64" {
  let result = try? coverage_eval("@base64d", "\"***\"")
  assert_true(result is Err(_))
}
