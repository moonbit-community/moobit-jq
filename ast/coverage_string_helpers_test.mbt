///|
test "coverage: more string search helpers" {
  @json.inspect(coverage_eval("index(\"foo\")", "\"foobar\""), content=[0])
  @json.inspect(coverage_eval("indices(\"o\")", "\"foobar\""), content=[[]])
}

///|
test "coverage: @html escapes ampersand and quotes" {
  @json.inspect(coverage_eval("@html", "\"&\\\"'\""), content=[
    "&amp;&quot;&#39;",
  ])
}
