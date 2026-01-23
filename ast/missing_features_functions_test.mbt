///|
test "missing: user-defined functions" {
  debug_inspect(
    test_feature("def double: . * 2; double", "5"),
    content="Number(10)",
  )
}

///|
test "missing: user-defined functions with params" {
  debug_inspect(
    test_feature("def add(x): . + x; add(10)", "5"),
    content=(
      #|EvalError: TypeMismatch("array", "number")
    ),
  )
}

///|
test "missing: recursive user-defined functions" {
  debug_inspect(
    test_feature(
      "def factorial: if . <= 1 then 1 else . * ((. - 1) | factorial) end; factorial",
      "5",
    ),
    content="Number(120)",
  )
}

///|
test "missing: comments in query" {
  debug_inspect(
    test_feature("# comment\n. + 1", "1"),
    content=(
      #|Number(2)
    ),
  )
}

///|
test "missing: multiline queries" {
  debug_inspect(
    test_feature(".\n+\n1", "1"),
    content=(
      #|Number(2)
    ),
  )
}
