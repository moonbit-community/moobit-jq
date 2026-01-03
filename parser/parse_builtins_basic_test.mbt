///|
/// Test parsing basic built-in functions
test "parse length" {
  @json.inspect(@parser.parse("length"), content="Length")
}

///|
test "parse keys" {
  @json.inspect(@parser.parse("keys"), content="Keys")
}

///|
test "parse type" {
  @json.inspect(@parser.parse("type"), content="Type")
}
