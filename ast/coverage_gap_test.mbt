///|
fn cov_eval4(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  eval(expr, json_input).collect()
}

///|
test "coverage: object constructor shorthand {a}" {
  @json.inspect(cov_eval4("{a}", "{\"a\": 1}"), content=[{ "a": 1 }])
  @json.inspect(cov_eval4("{a}", "{\"b\": 2}"), content=[{ "a": null }])
}

///|
test "coverage: keys on arrays yields numeric indices" {
  @json.inspect(cov_eval4("keys", "[10, 20]"), content=[[0, 1]])
}

///|
test "coverage: setpath and delpaths for nested arrays" {
  @json.inspect(cov_eval4("setpath([1]; 99)", "[10, 20, 30]"), content=[
    [10, 99, 30],
  ])
  @json.inspect(cov_eval4("setpath([1, 0]; 99)", "[[0], [1, 2]]"), content=[
    [[0], [99, 2]],
  ])
  @json.inspect(cov_eval4("delpaths([[1, 0]])", "[[0], [1, 2]]"), content=[
    [[0], [2]],
  ])
  @json.inspect(cov_eval4("delpaths([[\"missing\", \"x\"]])", "{\"a\": 1}"), content=[
    { "a": 1 },
  ])
}

///|
test "coverage: update operator keeps original when update yields empty" {
  @json.inspect(cov_eval4(".[0] |= empty", "[1]"), content=[[1]])
  @json.inspect(cov_eval4(".[10] |= . + 1", "[1]"), content=[[1]])
}

///|
test "coverage: base64 decode rejects invalid padding and characters" {
  // Padding in a non-final quantum.
  assert_true((try? cov_eval4("@base64d", "\"AA==AAAA\"")) is Err(_))
  // Invalid character in the 3rd position of a quantum.
  assert_true((try? cov_eval4("@base64d", "\"AA!A\"")) is Err(_))
  // Invalid character in the 4th position of a quantum.
  assert_true((try? cov_eval4("@base64d", "\"AAA!\"")) is Err(_))
  // Invalid character in the 1st/2nd position.
  assert_true((try? cov_eval4("@base64d", "\"!AAA\"")) is Err(_))
  assert_true((try? cov_eval4("@base64d", "\"A!AA\"")) is Err(_))
}

///|
test "coverage: parse_slice_part handles spaced negative index" {
  // Cover parser branch where '-' is tokenized separately from the number.
  @json.inspect(cov_eval4(".[- 1]", "[10, 20, 30]"), content=[30])
}
