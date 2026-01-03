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
test "coverage: getpath/setpath handle array segments" {
  @json.inspect(coverage_eval("getpath([1])", "[10, 20, 30]"), content=[20])
  @json.inspect(
    coverage_eval("setpath([\"a\", \"b\"]; 2)", "{\"a\": {\"b\": 1}}"),
    content=[{ "a": { "b": 2 } }],
  )
}
