///|
fn cov_eval2(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json_input = @json.parse(input[:])
  eval(expr, json_input).collect()
}

///|
test "coverage: flatten default depth flattens all" {
  @json.inspect(cov_eval2("flatten", "[1, [2, [3]]]"), content=[[1, 2, 3]])
}

///|
test "coverage: flatten(n) flattens one level" {
  @json.inspect(cov_eval2("flatten(1)", "[1, [2, [3]]]"), content=[[1, 2, [3]]])
}

///|
test "coverage: flatten rejects non-array" {
  assert_true((try? cov_eval2("flatten", "1")) is Err(_))
}

///|
test "coverage: unique sorts and removes duplicates" {
  @json.inspect(cov_eval2("unique", "[3, 1, 3, 2]"), content=[[1, 2, 3]])
}

///|
test "coverage: to_entries supports arrays" {
  @json.inspect(cov_eval2("to_entries", "[\"a\", \"b\"]"), content=[
    [{ "key": 0, "value": "a" }, { "key": 1, "value": "b" }],
  ])
}

///|
test "coverage: from_entries supports numeric keys and name fallback" {
  @json.inspect(cov_eval2("from_entries", "[{\"key\":0,\"value\":\"a\"}]"), content=[
    { "0": "a" },
  ])
  @json.inspect(cov_eval2("from_entries", "[{\"name\":\"a\",\"value\":1}]"), content=[
    { "a": 1 },
  ])
}

///|
test "coverage: with_entries round-trips object" {
  @json.inspect(cov_eval2("with_entries(.)", "{\"a\": 1, \"b\": 2}"), content=[
    { "a": 1, "b": 2 },
  ])
}

///|
test "coverage: range variants" {
  @json.inspect(cov_eval2("range(1; 4)", "null"), content=[1, 2, 3])
  @json.inspect(cov_eval2("range(0; 5; 2)", "null"), content=[0, 2, 4])
  @json.inspect(cov_eval2("range(5; 0; -2)", "null"), content=[5, 3, 1])
  assert_true((try? cov_eval2("range(\"a\"; 4)", "null")) is Err(_))
}

///|
test "coverage: first/last with generator" {
  @json.inspect(cov_eval2("first(.[])", "[1, 2, 3]"), content=[1])
  @json.inspect(cov_eval2("last(.[])", "[1, 2, 3]"), content=[3])
  @json.inspect(cov_eval2("first(empty)", "null"), content=[])
  @json.inspect(cov_eval2("last(empty)", "null"), content=[])
}

///|
test "coverage: any/all generator variants" {
  @json.inspect(cov_eval2("any(.[]; . > 2)", "[1, 3]"), content=[true])
  @json.inspect(cov_eval2("all(.[]; . > 2)", "[1, 3]"), content=[false])
  @json.inspect(cov_eval2("any(.[]; empty)", "[1, 3]"), content=[false])
  @json.inspect(cov_eval2("all(.[]; empty)", "[1, 3]"), content=[false])
}

///|
test "coverage: indices/index/rindex" {
  @json.inspect(cov_eval2("indices(2)", "[1, 2, 1, 2]"), content=[[1, 3]])
  @json.inspect(cov_eval2("index(2)", "[1, 2, 3]"), content=[1])
  @json.inspect(cov_eval2("index(9)", "[1, 2, 3]"), content=[null])
  @json.inspect(cov_eval2("rindex(\"o\")", "\"foobar\""), content=[2])
}

///|
test "coverage: select(empty) yields no outputs" {
  @json.inspect(cov_eval2(".[] | select(empty)", "[1, 2, 3]"), content=[])
}

///|
test "coverage: try-catch executes catch branch" {
  @json.inspect(cov_eval2("try (1 / 0) catch 42", "null"), content=[42])
}

///|
test "coverage: update operator supports chained paths and indices" {
  let input_obj : String =
    #|{
    #|  "a": { "b": 1 }
    #|}
  @json.inspect(cov_eval2(".a.b |= . + 1", input_obj), content=[
    { "a": { "b": 2 } },
  ])
  @json.inspect(cov_eval2(".[1] |= . + 10", "[1, 2, 3]"), content=[[1, 12, 3]])
}

///|
test "coverage: delpaths deletes array indices" {
  @json.inspect(cov_eval2("delpaths([[1]])", "[10, 20, 30]"), content=[[10, 30]])
}

///|
test "coverage: paths(filter) traverses arrays" {
  @json.inspect(cov_eval2("paths(type == \"number\")", "[1, [2]]"), content=[
    ["0"],
    ["1", "0"],
  ])
}

///|
test "coverage: @csv formats booleans and nulls" {
  @json.inspect(cov_eval2("@csv", "[1, true, false, null, \"x\"]"), content=[
    "1,true,false,,x",
  ])
}

///|
test "coverage: map_values transforms object values" {
  @json.inspect(cov_eval2("map_values(. + 1)", "{\"a\": 1, \"b\": 2}"), content=[
    { "a": 2, "b": 3 },
  ])
}

///|
test "coverage: getpath/setpath handle array segments" {
  @json.inspect(cov_eval2("getpath([1])", "[10, 20, 30]"), content=[20])
  @json.inspect(
    cov_eval2("setpath([\"a\", \"b\"]; 2)", "{\"a\": {\"b\": 1}}"),
    content=[{ "a": { "b": 2 } }],
  )
}
