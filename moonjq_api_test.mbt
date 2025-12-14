///|
fn collect(it : Iterator[Json]) -> Array[Json] {
  it.collect()
}

///|
test "api: parse succeeds" {
  let result = try? parse(".a")
  assert_true(result is Ok(_))
}

///|
test "api: eval streams results" {
  let query = parse(".a")
  let input = @json.parse("{\"a\": 1}"[:])
  @json.inspect(collect(eval(query, input)), content=[1])
}

///|
test "api: eval_all collects results" {
  let query = parse(".a")
  let input = @json.parse("{\"a\": 1}"[:])
  @json.inspect(eval_all(query, input), content=[1])
}

///|
test "api: run parses strings and collects" {
  @json.inspect(run(".a", "{\"a\": 1}"), content=[1])
}

///|
test "api: run_json reuses compiled query" {
  let query = parse(".a")
  let json = @json.parse("{\"a\": 2}"[:])
  @json.inspect(run_json(query, json), content=[2])
}

///|
test "api: eval_logs processes newline logs" {
  let query = parse(".a")
  let logs : String =
    #|{
    #|{"a":1}
    #|not json
    #|{"a":2}
    #|}
  @json.inspect(collect(query.eval_logs(logs)), content=[1, 2])
}

///|
test "api: eval_logs handles CRLF" {
  let query = parse(".a")
  // let logs = "{\"a\":3}\r\n\r\ninvalid\r\n{\"a\":4}\r\n"
  let logs =
    #|{"a":3}
    #|
    #|invalid
    #|{"a":4}
    #|
  @json.inspect(collect(query.eval_logs(logs)), content=[3, 4])
}

///|
test "api: eval_logs handle diagsnotics" {
  let logs =
    #| {"$message_type":"diagnostic","level":"error","loc":{"path":"/Users/dii/git/system-prompt/moonjq_api_test.mbt","start":{"line":64,"col":3},"end":{"line":64,"col":4}},"message":"The value identifier x is unbound.","error_code":4021}
    #| {"$message_type":"diagnostic","level":"error","loc":{"path":"/Users/dii/git/system-prompt/moonjq_api_test.mbt","start":{"line":64,"col":3},"end":{"line":64,"col":4}},"message":"The value identifier y is unbound.","error_code":4021}#|
    #| Failed with 0 warnings, 0 errors.
    #| error: failed when checking project
    #|
  @json.inspect(collect(parse(".message").eval_logs(logs)), content=[
    "The value identifier x is unbound.",
  ])
}
