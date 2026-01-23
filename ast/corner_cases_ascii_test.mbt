///|
/// Corner case tests for ASCII casing

///|
test "corner: ascii_downcase preserves non-ASCII" {
  debug_inspect(
    test_query("ascii_downcase", "\"CAFÉ\""),
    content="String(\"cafÉ\")",
  )
}

///|
test "corner: ascii_upcase preserves non-ASCII" {
  debug_inspect(
    test_query("ascii_upcase", "\"café\""),
    content=(
      #|String("CAFé")
    ),
  )
}
