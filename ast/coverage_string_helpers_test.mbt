///|
test "coverage: more string search helpers" {
  json_inspect(coverage_eval("index(\"foo\")", "\"foobar\""), content=[0])
  json_inspect(coverage_eval("indices(\"o\")", "\"foobar\""), content=[[1, 2]])
}

///|
test "string index operations" {
  // index: find first occurrence
  json_inspect(coverage_eval("index(\"bc\")", "\"abcabc\""), content=[1])
  json_inspect(coverage_eval("index(\"xyz\")", "\"abcabc\""), content=[null])
  json_inspect(coverage_eval("index(\"abc\")", "\"abcabc\""), content=[0])
  json_inspect(coverage_eval("index(\"c\")", "\"abcabc\""), content=[2])
  json_inspect(coverage_eval("index(\"world\")", "\"hello world\""), content=[6])
  // indices: find all occurrences
  json_inspect(coverage_eval("indices(\"bc\")", "\"abcabc\""), content=[[1, 4]])
  json_inspect(coverage_eval("indices(\"a\")", "\"abcabc\""), content=[[0, 3]])
  json_inspect(coverage_eval("indices(\"xyz\")", "\"abcabc\""), content=[[]])
  json_inspect(coverage_eval("indices(\"abc\")", "\"abcabc\""), content=[[0, 3]])
  json_inspect(coverage_eval("indices(\"abc\")", "\"abcabcabc\""), content=[
    [0, 3, 6],
  ])
  // Overlapping matches (jq behavior: finds overlapping matches)
  json_inspect(coverage_eval("indices(\"aa\")", "\"aaaa\""), content=[[0, 1, 2]])
  // Edge cases
  json_inspect(coverage_eval("indices(\"\")", "\"abc\""), content=[[]])
  json_inspect(coverage_eval("index(\"\")", "\"abc\""), content=[null])
}

///|
test "coverage: @html escapes ampersand and quotes" {
  json_inspect(coverage_eval("@html", "\"&\\\"'\""), content=[
    "&amp;&quot;&#39;",
  ])
}
