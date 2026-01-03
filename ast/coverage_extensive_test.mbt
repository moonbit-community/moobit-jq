///|
test "coverage: flatten default depth flattens all" {
  @json.inspect(coverage_eval("flatten", "[1, [2, [3]]]"), content=[[1, 2, 3]])
}

///|
test "coverage: flatten(n) flattens one level" {
  @json.inspect(coverage_eval("flatten(1)", "[1, [2, [3]]]"), content=[[1, 2, [3]]])
}

///|
test "coverage: flatten rejects non-array" {
  assert_true((try? coverage_eval("flatten", "1")) is Err(_))
}

///|
test "coverage: unique sorts and removes duplicates" {
  @json.inspect(coverage_eval("unique", "[3, 1, 3, 2]"), content=[[1, 2, 3]])
}

///|
test "coverage: to_entries supports arrays" {
  @json.inspect(coverage_eval("to_entries", "[\"a\", \"b\"]"), content=[
    [{ "key": 0, "value": "a" }, { "key": 1, "value": "b" }],
  ])
}

///|
test "coverage: from_entries supports numeric keys and name fallback" {
  @json.inspect(coverage_eval("from_entries", "[{\"key\":0,\"value\":\"a\"}]"), content=[
    { "0": "a" },
  ])
  @json.inspect(coverage_eval("from_entries", "[{\"name\":\"a\",\"value\":1}]"), content=[
    { "a": 1 },
  ])
}

///|
test "coverage: with_entries round-trips object" {
  @json.inspect(coverage_eval("with_entries(.)", "{\"a\": 1, \"b\": 2}"), content=[
    { "a": 1, "b": 2 },
  ])
}

///|
test "coverage: range variants" {
  @json.inspect(coverage_eval("range(1; 4)", "null"), content=[1, 2, 3])
  @json.inspect(coverage_eval("range(0; 5; 2)", "null"), content=[0, 2, 4])
  @json.inspect(coverage_eval("range(5; 0; -2)", "null"), content=[5, 3, 1])
  assert_true((try? coverage_eval("range(\"a\"; 4)", "null")) is Err(_))
}

///|
test "coverage: first/last with generator" {
  @json.inspect(coverage_eval("first(.[])", "[1, 2, 3]"), content=[1])
  @json.inspect(coverage_eval("last(.[])", "[1, 2, 3]"), content=[3])
  @json.inspect(coverage_eval("first(empty)", "null"), content=[])
  @json.inspect(coverage_eval("last(empty)", "null"), content=[])
}

///|
test "coverage: any/all generator variants" {
  @json.inspect(coverage_eval("any(.[]; . > 2)", "[1, 3]"), content=[true])
  @json.inspect(coverage_eval("all(.[]; . > 2)", "[1, 3]"), content=[false])
  @json.inspect(coverage_eval("any(.[]; empty)", "[1, 3]"), content=[false])
  @json.inspect(coverage_eval("all(.[]; empty)", "[1, 3]"), content=[false])
}

///|
test "coverage: indices/index/rindex" {
  @json.inspect(coverage_eval("indices(2)", "[1, 2, 1, 2]"), content=[[1, 3]])
  @json.inspect(coverage_eval("index(2)", "[1, 2, 3]"), content=[1])
  @json.inspect(coverage_eval("index(9)", "[1, 2, 3]"), content=[null])
  @json.inspect(coverage_eval("rindex(\"o\")", "\"foobar\""), content=[2])
}

///|
test "coverage: select(empty) yields no outputs" {
  @json.inspect(coverage_eval(".[] | select(empty)", "[1, 2, 3]"), content=[])
}

///|
test "coverage: try-catch executes catch branch" {
  @json.inspect(coverage_eval("try (1 / 0) catch 42", "null"), content=[42])
}

///|
test "coverage: update operator supports chained paths and indices" {
  let input_obj : String =
    #|{
    #|  "a": { "b": 1 }
    #|}
  @json.inspect(coverage_eval(".a.b |= . + 1", input_obj), content=[
    { "a": { "b": 2 } },
  ])
  @json.inspect(coverage_eval(".[1] |= . + 10", "[1, 2, 3]"), content=[[1, 12, 3]])
}

///|
test "coverage: delpaths deletes array indices" {
  @json.inspect(coverage_eval("delpaths([[1]])", "[10, 20, 30]"), content=[[10, 30]])
}

///|
test "coverage: paths(filter) traverses arrays" {
  @json.inspect(coverage_eval("paths(type == \"number\")", "[1, [2]]"), content=[
    ["0"],
    ["1", "0"],
  ])
}

///|
test "coverage: @csv formats booleans and nulls" {
  @json.inspect(coverage_eval("@csv", "[1, true, false, null, \"x\"]"), content=[
    "1,true,false,,x",
  ])
}

///|
test "coverage: map_values transforms object values" {
  @json.inspect(coverage_eval("map_values(. + 1)", "{\"a\": 1, \"b\": 2}"), content=[
    { "a": 2, "b": 3 },
  ])
}

///|
test "coverage: sort_by empty key uses null" {
  @json.inspect(coverage_eval("sort_by(empty)", "[2]"), content=[[2]])
}

///|
test "coverage: group_by empty key uses null" {
  @json.inspect(coverage_eval("group_by(empty)", "[1, 2]"), content=[[[1, 2]]])
}

///|
test "coverage: getpath/setpath handle array segments" {
  @json.inspect(coverage_eval("getpath([1])", "[10, 20, 30]"), content=[20])
  @json.inspect(
    coverage_eval("setpath([\"a\", \"b\"]; 2)", "{\"a\": {\"b\": 1}}"),
    content=[{ "a": { "b": 2 } }],
  )
}
