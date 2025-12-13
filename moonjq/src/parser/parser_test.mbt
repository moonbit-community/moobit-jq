///|
/// Test parsing identity
test "parse identity" {
  let expr = @parser.parse(".")
  @json.inspect(expr, content="Identity")
}

///|
/// Test parsing literals
test "parse null literal" {
  let expr = @parser.parse("null")
  @json.inspect(expr, content=["Literal", "Null"])
}

///|
test "parse boolean literals" {
  @json.inspect(@parser.parse("true"), content=["Literal", ["Bool", true]])
  @json.inspect(@parser.parse("false"), content=["Literal", ["Bool", false]])
}

///|
test "parse number literals" {
  @json.inspect(@parser.parse("42"), content=["Literal", ["Number", 42]])
  @json.inspect(@parser.parse("3.14"), content=["Literal", ["Number", 3.14]])
}

///|
test "parse string literal" {
  @json.inspect(@parser.parse("\"hello\""), content=[
    "Literal",
    ["String", "hello"],
  ])
}

///|
/// Test parsing field access
test "parse field access" {
  @json.inspect(@parser.parse(".foo"), content=["Key", "foo"])
}

///|
test "parse nested field access" {
  @json.inspect(@parser.parse(".foo.bar"), content=[
    "Pipe",
    ["Key", "foo"],
    ["Key", "bar"],
  ])
}

///|
/// Test parsing array operations
test "parse array index" {
  @json.inspect(@parser.parse(".[0]"), content=[
    "Pipe",
    "Identity",
    ["Index", [0]],
  ])
}

///|
test "parse multiple indices" {
  @json.inspect(@parser.parse(".[0,2,4]"), content=[
    "Pipe",
    "Identity",
    ["Index", [0, 2, 4]],
  ])
}

///|
test "parse array iterator" {
  @json.inspect(@parser.parse(".[]"), content=[
    "Pipe",
    "Identity",
    ["Index", []],
  ])
}

///|
test "parse array slice" {
  @json.inspect(@parser.parse(".[2:4]"), content=[
    "Pipe",
    "Identity",
    ["Slice", [2], [4]],
  ])
}

///|
test "parse open-ended slices" {
  @json.inspect(@parser.parse(".[2:]"), content=[
    "Pipe",
    "Identity",
    ["Slice", [2], null],
  ])
  @json.inspect(@parser.parse(".[:4]"), content=[
    "Pipe",
    "Identity",
    ["Slice", null, [4]],
  ])
}

///|
/// Test parsing pipe operator
test "parse pipe" {
  @json.inspect(@parser.parse(". | .foo"), content=[
    "Pipe",
    "Identity",
    ["Key", "foo"],
  ])
}

///|
test "parse chained pipes" {
  @json.inspect(@parser.parse(".a | .b | .c"), content=[
    "Pipe",
    ["Pipe", ["Key", "a"], ["Key", "b"]],
    ["Key", "c"],
  ])
}

///|
/// Test parsing comma operator
test "parse comma" {
  @json.inspect(@parser.parse(".a, .b"), content=[
    "Comma",
    ["Key", "a"],
    ["Key", "b"],
  ])
}

///|
/// Test parsing arithmetic operators
test "parse addition" {
  @json.inspect(@parser.parse(". + 1"), content=[
    "Operation",
    "Identity",
    "Add",
    ["Literal", ["Number", 1]],
  ])
}

///|
test "parse subtraction" {
  @json.inspect(@parser.parse(". - 1"), content=[
    "Operation",
    "Identity",
    "Subtract",
    ["Literal", ["Number", 1]],
  ])
}

///|
test "parse multiplication" {
  @json.inspect(@parser.parse(". * 2"), content=[
    "Operation",
    "Identity",
    "Multiply",
    ["Literal", ["Number", 2]],
  ])
}

///|
test "parse division" {
  @json.inspect(@parser.parse(". / 2"), content=[
    "Operation",
    "Identity",
    "Divide",
    ["Literal", ["Number", 2]],
  ])
}

///|
test "parse modulo" {
  @json.inspect(@parser.parse(". % 2"), content=[
    "Operation",
    "Identity",
    "Modulo",
    ["Literal", ["Number", 2]],
  ])
}

///|
/// Test operator precedence
test "parse precedence: multiplication before addition" {
  @json.inspect(@parser.parse("1 + 2 * 3"), content=[
    "Operation",
    ["Literal", ["Number", 1]],
    "Add",
    [
      "Operation",
      ["Literal", ["Number", 2]],
      "Multiply",
      ["Literal", ["Number", 3]],
    ],
  ])
}

///|
test "parse parentheses override precedence" {
  @json.inspect(@parser.parse("(1 + 2) * 3"), content=[
    "Operation",
    ["Operation", ["Literal", ["Number", 1]], "Add", ["Literal", ["Number", 2]]],
    "Multiply",
    ["Literal", ["Number", 3]],
  ])
}

///|
/// Test parsing comparison operators
test "parse equality" {
  @json.inspect(@parser.parse(". == 5"), content=[
    "Operation",
    "Identity",
    "Equal",
    ["Literal", ["Number", 5]],
  ])
}

///|
test "parse inequality" {
  @json.inspect(@parser.parse(". != 5"), content=[
    "Operation",
    "Identity",
    "NotEqual",
    ["Literal", ["Number", 5]],
  ])
}

///|
test "parse less than" {
  @json.inspect(@parser.parse(". < 5"), content=[
    "Operation",
    "Identity",
    "LessThan",
    ["Literal", ["Number", 5]],
  ])
}

///|
test "parse greater than" {
  @json.inspect(@parser.parse(". > 5"), content=[
    "Operation",
    "Identity",
    "GreaterThan",
    ["Literal", ["Number", 5]],
  ])
}

///|
/// Test parsing logical operators
test "parse and" {
  @json.inspect(@parser.parse(".a and .b"), content=[
    "Operation",
    ["Key", "a"],
    "And",
    ["Key", "b"],
  ])
}

///|
test "parse or" {
  @json.inspect(@parser.parse(".a or .b"), content=[
    "Operation",
    ["Key", "a"],
    "Or",
    ["Key", "b"],
  ])
}

///|
test "parse not" {
  @json.inspect(@parser.parse("not"), content="Not")
}

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

///|
/// Test parsing optional operator
test "parse optional" {
  @json.inspect(@parser.parse(".foo?"), content=["Optional", ["Key", "foo"]])
}

///|
/// Test parsing if-then-else
test "parse if-then-else" {
  @json.inspect(@parser.parse("if .x then .y else .z end"), content=[
    "IfThenElse",
    ["Key", "x"],
    ["Key", "y"],
    ["Key", "z"],
  ])
}

///|
/// Test parsing try-catch
test "parse try without catch" {
  @json.inspect(@parser.parse("try .foo"), content=[
    "TryCatch",
    ["Key", "foo"],
    null,
  ])
}

///|
test "parse try with catch" {
  @json.inspect(@parser.parse("try .foo catch .bar"), content=[
    "TryCatch",
    ["Key", "foo"],
    [["Key", "bar"]],
  ])
}

///|
/// Test parsing variables
test "parse variable" {
  @json.inspect(@parser.parse("$foo"), content=["Variable", "foo"])
}

///|
/// Test parsing built-in functions
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

///|
test "parse map" {
  @json.inspect(@parser.parse("map(. + 1)"), content=[
    "Map",
    ["Operation", "Identity", "Add", ["Literal", ["Number", 1]]],
  ])
}

///|
test "parse select" {
  @json.inspect(@parser.parse("select(. > 5)"), content=[
    "Select",
    ["Operation", "Identity", "GreaterThan", ["Literal", ["Number", 5]]],
  ])
}

///|
test "parse sort" {
  @json.inspect(@parser.parse("sort"), content="Sort")
}

///|
test "parse flatten" {
  @json.inspect(@parser.parse("flatten"), content=["Flatten", null])
  @json.inspect(@parser.parse("flatten(2)"), content=["Flatten", [2]])
}

///|
/// Test parsing recurse
test "parse recurse" {
  @json.inspect(@parser.parse(".."), content="Recurse")
}

///|
/// Test parsing assignment operators
test "parse update" {
  @json.inspect(@parser.parse(".foo |= . + 1"), content=[
    "Update",
    ["Key", "foo"],
    ["Operation", "Identity", "Add", ["Literal", ["Number", 1]]],
  ])
}

///|
test "parse alternative" {
  @json.inspect(@parser.parse(".foo // .bar"), content=[
    "Alternative",
    ["Key", "foo"],
    ["Key", "bar"],
  ])
}

///|
/// Test complex expressions
test "parse complex filter" {
  @json.inspect(@parser.parse(".[] | select(.age > 18) | .name"), content=[
    "Pipe",
    [
      "Pipe",
      ["Pipe", "Identity", ["Index", []]],
      [
        "Select",
        [
          "Operation",
          ["Key", "age"],
          "GreaterThan",
          ["Literal", ["Number", 18]],
        ],
      ],
    ],
    ["Key", "name"],
  ])
}

///|
/// Test error handling
test "panic unexpected token" {
  inspect(
    try? @parser.parse("@"),
    content=(
      #|Err(UnexpectedToken(TAt, "expression"))
    ),
  )
}

///|
test "panic unexpected end" {
  inspect(
    try? @parser.parse("if .x then"),
    content=(
      #|Err(UnexpectedEnd("TElse"))
    ),
  )
}
