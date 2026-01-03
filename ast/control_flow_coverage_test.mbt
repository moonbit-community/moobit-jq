///|
test "coverage: while yields intermediate values" {
  @json.inspect(coverage_eval("while(. < 4; . + 1)", "1"), content=[1, 2, 3])
}

///|
test "coverage: until terminates and returns final value" {
  @json.inspect(coverage_eval("until(. > 3; . + 1)", "1"), content=[4])
}

///|
test "coverage: limit takes first N results" {
  @json.inspect(coverage_eval("limit(2; .[])", "[1, 2, 3]"), content=[1, 2])
}

///|
test "coverage: reduce aggregates with variable binding" {
  @json.inspect(coverage_eval("reduce .[] as $x (0; . + $x)", "[1, 2, 3]"), content=[
    6,
  ])
}

///|
test "coverage: foreach emits running accumulator" {
  @json.inspect(coverage_eval("foreach .[] as $x (0; . + $x)", "[1, 2, 3]"), content=[
    1, 3, 6,
  ])
}

///|
test "coverage: foreach supports extract expression" {
  @json.inspect(
    coverage_eval("foreach .[] as $x (0; . + $x; . * 2)", "[1, 2, 3]"),
    content=[2, 6, 12],
  )
}

///|
test "coverage: scan emits non-overlapping matches" {
  @json.inspect(coverage_eval("scan(\"aa\")", "\"aaaaa\""), content=["aa", "aa"])
}

///|
test "coverage: recurse(f; cond) applies f transitively" {
  let input : String =
    #|{
    #|  "a": {
    #|    "a": null
    #|  }
    #|}
  @json.inspect(coverage_eval("recurse(.a; . != null)", input), content=[
    { "a": { "a": null } },
    { "a": null },
    null,
  ])
}

///|
test "coverage: walk transforms nested numbers" {
  let input : String =
    #|{
    #|  "a": [1, { "b": 2 }],
    #|  "c": "x"
    #|}
  @json.inspect(
    coverage_eval("walk(if type == \"number\" then . + 1 else . end)", input),
    content=[{ "a": [2, { "b": 3 }], "c": "x" }],
  )
}
