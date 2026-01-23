///|
test "missing: limit(n; expr)" {
  debug_inspect(
    test_feature("limit(2; .[])", "[1,2,3,4,5]"),
    content=(
      #|Number(1)
      #|Number(2)
    ),
  )
}

///|
// Temporarily disabled
// test "missing: until(cond; update)" {
//   inspect(test_feature("1 | until(. > 5; . + 1)", "null"), content="")
// }

///|
// Temporarily disabled - causes infinite loop
// test "missing: while(cond; update)" {
//   inspect(test_feature("1 | while(. < 5; . + 1)", "null"), content="")
// }

///|
// Temporarily disabled
// test "missing: recurse with condition" {
//   inspect(test_feature("recurse(.+1; . < 5)", "1"), content="")
// }

///|
test "missing: walk function" {
  debug_inspect(
    test_feature(
      "walk(if type == \"number\" then . * 2 else . end)", "{\"a\":1,\"b\":[2,3]}",
    ),
    content=(
      #|Object({"a": Number(2), "b": Array([Number(4), Number(6)])})
    ),
  )
}

///|
test "missing: update operator |=" {
  debug_inspect(
    test_feature(".a |= . + 1", "{\"a\":5}"),
    content="Object({\"a\": Number(6)})",
  )
}

///|
test "missing: assignment operator =" {
  debug_inspect(test_feature(".a = 10", "{\"a\":5}"), content="Number(10)")
}

///|
test "missing: alternative operator //" {
  debug_inspect(
    test_feature(".missing // \"default\"", "{}"),
    content=(
      #|String("default")
    ),
  )
}

///|
test "missing: += operator" {
  debug_inspect(
    test_feature(".a += 3", "{\"a\":5}"),
    content="Object({\"a\": Number(8)})",
  )
}

///|
test "missing: -= operator" {
  debug_inspect(
    test_feature(".a -= 3", "{\"a\":5}"),
    content="Object({\"a\": Number(2)})",
  )
}

///|
test "missing: *= operator" {
  debug_inspect(
    test_feature(".a *= 3", "{\"a\":5}"),
    content="Object({\"a\": Number(15)})",
  )
}

///|
test "missing: /= operator" {
  debug_inspect(
    test_feature(".a /= 2", "{\"a\":5}"),
    content="Object({\"a\": Number(2.5)})",
  )
}

///|
test "missing: %= operator" {
  debug_inspect(
    test_feature(".a %= 2", "{\"a\":5}"),
    content="Object({\"a\": Number(1)})",
  )
}

///|
test "missing: //= operator" {
  debug_inspect(
    test_feature(".a //= 10", "{\"a\":5}"),
    content="Object({\"a\": Number(5)})",
  )
}
