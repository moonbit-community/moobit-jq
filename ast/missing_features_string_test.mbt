///|
test "missing: ltrimstr" {
  inspect(
    test_feature(".text | ltrimstr(\"hello \")", "{\"text\":\"hello world\"}"),
    content=(
      #|String("world")
    ),
  )
}

///|
test "missing: rtrimstr" {
  inspect(
    test_feature(".text | rtrimstr(\" world\")", "{\"text\":\"hello world\"}"),
    content=(
      #|String("hello")
    ),
  )
}

///|
test "missing: ascii_upcase" {
  inspect(
    test_feature(".text | ascii_upcase", "{\"text\":\"hello\"}"),
    content=(
      #|String("HELLO")
    ),
  )
}

///|
test "missing: ascii_downcase" {
  inspect(
    test_feature(".text | ascii_downcase", "{\"text\":\"HELLO\"}"),
    content=(
      #|String("hello")
    ),
  )
}

///|
test "missing: string interpolation" {
  inspect(
    test_feature("\"Hello \\(.name)\"", "{\"name\":\"World\"}"),
    content=(
      #|String("Hello World")
    ),
  )
}
