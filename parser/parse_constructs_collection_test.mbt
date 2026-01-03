///|
/// Test parsing array constructor
test "parse empty array" {
  @json.inspect(@parser.parse("[]"), content=["ArrayConstruct", null])
}

///|
test "parse array with expression" {
  @json.inspect(@parser.parse("[.foo]"), content=[
    "ArrayConstruct",
    [["Key", "foo"]],
  ])
}

///|
/// Test parsing object constructor
test "parse empty object" {
  @json.inspect(@parser.parse("{}"), content=["ObjectConstruct", []])
}

///|
test "parse object with single field" {
  @json.inspect(@parser.parse("{foo: .bar}"), content=[
    "ObjectConstruct",
    [[["Literal", ["String", "foo"]], [["Key", "bar"]]]],
  ])
}

///|
test "parse object with multiple fields" {
  @json.inspect(@parser.parse("{a: .x, b: .y}"), content=[
    "ObjectConstruct",
    [
      [["Literal", ["String", "a"]], [["Key", "x"]]],
      [["Literal", ["String", "b"]], [["Key", "y"]]],
    ],
  ])
}
