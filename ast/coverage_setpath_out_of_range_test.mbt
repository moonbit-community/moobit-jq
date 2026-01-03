///|
test "coverage: setpath out-of-range keeps original" {
  @json.inspect(coverage_eval("setpath([10]; 1)", "[0]"), content=[[0]])
}
