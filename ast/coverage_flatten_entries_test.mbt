///|
test "coverage: flatten default depth flattens all" {
  json_inspect(coverage_eval("flatten", "[1, [2, [3]]]"), content=[[1, 2, 3]])
}

///|
test "coverage: flatten(n) flattens one level" {
  json_inspect(coverage_eval("flatten(1)", "[1, [2, [3]]]"), content=[
    [1, 2, [3]],
  ])
}

///|
test "coverage: flatten rejects non-array" {
  assert_true((try? coverage_eval("flatten", "1")) is Err(_))
}

///|
test "coverage: unique sorts and removes duplicates" {
  json_inspect(coverage_eval("unique", "[3, 1, 3, 2]"), content=[[1, 2, 3]])
}

///|
test "coverage: to_entries supports arrays" {
  json_inspect(coverage_eval("to_entries", "[\"a\", \"b\"]"), content=[
    [{ "key": 0, "value": "a" }, { "key": 1, "value": "b" }],
  ])
}

///|
test "coverage: from_entries supports numeric keys and name fallback" {
  json_inspect(coverage_eval("from_entries", "[{\"key\":0,\"value\":\"a\"}]"), content=[
    { "0": "a" },
  ])
  json_inspect(
    coverage_eval("from_entries", "[{\"name\":\"a\",\"value\":1}]"),
    content=[{ "a": 1 }],
  )
}

///|
test "coverage: with_entries round-trips object" {
  json_inspect(coverage_eval("with_entries(.)", "{\"a\": 1, \"b\": 2}"), content=[
    { "a": 1, "b": 2 },
  ])
}
