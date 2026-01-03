///|
test "coverage: sort_by empty key uses null" {
  @json.inspect(coverage_eval("sort_by(empty)", "[2]"), content=[[2]])
}

///|
test "coverage: group_by empty key uses null" {
  @json.inspect(coverage_eval("group_by(empty)", "[1, 2]"), content=[[[1, 2]]])
}
