///|
test "missing: values function" {
  debug_inspect(
    test_feature("values", "[1,2,null,3]"),
    content="Array([Number(1), Number(2), Null, Number(3)])",
  )
}

///|
test "missing: nth(n)" {
  debug_inspect(test_feature("nth(1)", "[10,20,30]"), content="Number(20)")
}

///|
test "missing: rindex" {
  debug_inspect(
    test_feature("[1,2,3,2,1] | rindex(2)", "null"),
    content="Number(3)",
  )
}

///|
test "missing: paths" {
  debug_inspect(
    test_feature("paths", "{\"a\":{\"b\":1},\"c\":[2,3]}"),
    content=(
      #|Array([String("a")])
      #|Array([String("a"), String("b")])
      #|Array([String("c")])
      #|Array([String("c"), Number(0)])
      #|Array([String("c"), Number(1)])
    ),
  )
}

///|
test "missing: leaf_paths" {
  debug_inspect(
    test_feature("leaf_paths", "{\"a\":{\"b\":1},\"c\":[2,3]}"),
    content=(
      #|Array([String("a"), String("b")])
      #|Array([String("c"), Number(0)])
      #|Array([String("c"), Number(1)])
    ),
  )
}

///|
test "missing: getpath" {
  debug_inspect(
    test_feature("getpath([\"a\",\"b\"])", "{\"a\":{\"b\":42}}"),
    content="Number(42)",
  )
}

///|
test "missing: setpath" {
  debug_inspect(
    test_feature("setpath([\"a\",\"b\"]; 99)", "{\"a\":{\"b\":42}}"),
    content=(
      #|Object({"a": Object({"b": Number(99)})})
    ),
  )
}

///|
test "missing: delpaths" {
  debug_inspect(
    test_feature("delpaths([[\"a\",\"b\"]])", "{\"a\":{\"b\":42,\"c\":1}}"),
    content=(
      #|Object({"a": Object({"c": Number(1)})})
    ),
  )
}
