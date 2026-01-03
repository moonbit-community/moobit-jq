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
