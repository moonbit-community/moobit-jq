///|
test "missing: @base64 format" {
  debug_inspect(
    test_feature("@base64", "\"hello\""),
    content=(
      #|String("aGVsbG8=")
    ),
  )
}

///|
test "missing: @base64d format" {
  debug_inspect(
    test_feature("@base64d", "\"aGVsbG8=\""),
    content=(
      #|String("hello")
    ),
  )
}

///|
test "missing: @uri format" {
  debug_inspect(
    test_feature("@uri", "\"hello world\""),
    content=(
      #|String("hello%20world")
    ),
  )
}

///|
test "missing: @csv format" {
  debug_inspect(
    test_feature("@csv", "[[1,2,3]]"),
    content=(
      #|String("Array([Number(1), Number(2), Number(3)])")
    ),
  )
}

///|
test "missing: @json format" {
  debug_inspect(
    test_feature("@json", "{\"a\":1}"),
    content=(
      #|String("Object({\"a\": Number(1)})")
    ),
  )
}

///|
test "missing: @html format" {
  debug_inspect(
    test_feature("@html", "\"<div>\""),
    content=(
      #|String("&lt;div&gt;")
    ),
  )
}

///|
test "missing: @text format" {
  debug_inspect(
    test_feature("@text", "\"hello\""),
    content=(
      #|String("String(\"hello\")")
    ),
  )
}

///|
test "missing: test(regex)" {
  debug_inspect(
    test_feature(".text | test(\"^hello\")", "{\"text\":\"hello world\"}"),
    content="False",
  )
}

///|
test "missing: match(regex)" {
  debug_inspect(
    test_feature(".text | match(\"[0-9]+\")", "{\"text\":\"abc123def\"}"),
    content="",
  )
}

///|
test "missing: capture(regex)" {
  debug_inspect(
    test_feature(
      ".text | capture(\"(?<num>[0-9]+)\")", "{\"text\":\"abc123def\"}",
    ),
    content="Object({})",
  )
}

///|
test "missing: splits(regex)" {
  debug_inspect(
    test_feature(".text | splits(\" +\")", "{\"text\":\"hello   world\"}"),
    content=(
      #|String("hello   world")
    ),
  )
}

///|
test "missing: sub(regex; replacement)" {
  debug_inspect(
    test_feature(
      ".text | sub(\"world\"; \"MoonBit\")", "{\"text\":\"hello world\"}",
    ),
    content=(
      #|String("hello MoonBit")
    ),
  )
}

///|
test "missing: gsub(regex; replacement)" {
  debug_inspect(
    test_feature(".text | gsub(\"o\"; \"0\")", "{\"text\":\"hello world\"}"),
    content=(
      #|String("hell0 w0rld")
    ),
  )
}
