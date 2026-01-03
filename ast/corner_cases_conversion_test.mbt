///|
/// Corner case tests for string/array conversion

///|
test "corner: explode converts string to codepoints" {
  inspect(
    test_query("explode", "\"Hello\""),
    content="Array([Number(72), Number(101), Number(108), Number(108), Number(111)])",
  )
}

///|
test "corner: implode converts codepoints to string" {
  inspect(
    test_query("implode", "[72,101,108,108,111]"),
    content="String(\"Hello\")",
  )
}

///|
test "corner: explode with unicode" {
  inspect(
    test_query("explode", "\"世界\""),
    content="Array([Number(19990), Number(30028)])",
  )
}

///|
test "corner: implode with unicode codepoints" {
  inspect(test_query("implode", "[19990,30028]"), content="String(\"世界\")")
}
