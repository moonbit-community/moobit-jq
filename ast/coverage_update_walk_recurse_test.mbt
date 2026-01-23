///|
test "coverage: update operator branches" {
  json_inspect(coverage_eval(". |= empty", "1"), content=[1])
  json_inspect(coverage_eval(". |= 2", "1"), content=[2])
  json_inspect(coverage_eval(".a |= empty", "{\"a\": 1}"), content=[{ "a": 1 }])
  json_inspect(coverage_eval(".a |= . + 1", "1"), content=[1])
  json_inspect(coverage_eval(".[0] |= empty", "[1]"), content=[[1]])
  json_inspect(coverage_eval(".[10] |= . + 1", "[1]"), content=[[1]])
  json_inspect(coverage_eval(".[] |= .", "[1, 2]"), content=[[1, 2]])
  json_inspect(coverage_eval(".a[10] |= . + 1", "{\"a\": [1]}"), content=[
    { "a": [1] },
  ])
  json_inspect(coverage_eval(".foo.bar |= . + 1", "{\"foo\": {\"bar\": 1}}"), content=[
    { "foo": { "bar": 2 } },
  ])
  json_inspect(coverage_eval(".foo[0] |= . + 1", "{\"foo\": [1]}"), content=[
    { "foo": [2] },
  ])
}

///|
test "coverage: walk empty results and recurse safety" {
  json_inspect(coverage_eval("walk(empty)", "[1, 2]"), content=[[1, 2]])
  json_inspect(coverage_eval("walk(empty)", "{\"a\": 1}"), content=[{ "a": 1 }])
  json_inspect(coverage_eval("walk(empty)", "1"), content=[1])
  let nums : Array[String] = []
  for i in 0..<101 {
    nums.push(i.to_string())
  }
  let sep = ","
  let input = "[\{nums.join(sep)}]"
  let results = coverage_eval("recurse(.[]; . != null)", input)
  debug_inspect(results.length(), content="102")
}
