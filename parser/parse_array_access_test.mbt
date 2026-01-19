///|
/// Test parsing array operations
test "parse array index" {
  json_inspect(@parser.parse(".[0]"), content=[
    "Pipe",
    "Identity",
    ["Index", [0]],
  ])
}

///|
test "parse multiple indices" {
  json_inspect(@parser.parse(".[0,2,4]"), content=[
    "Pipe",
    "Identity",
    ["Index", [0, 2, 4]],
  ])
}

///|
test "parse array iterator" {
  json_inspect(@parser.parse(".[]"), content=["Pipe", "Identity", ["Index", []]])
}

///|
test "parse array slice" {
  json_inspect(@parser.parse(".[2:4]"), content=[
    "Pipe",
    "Identity",
    ["Slice", [2], [4]],
  ])
}

///|
test "parse open-ended slices" {
  json_inspect(@parser.parse(".[2:]"), content=[
    "Pipe",
    "Identity",
    ["Slice", [2], null],
  ])
  json_inspect(@parser.parse(".[:4]"), content=[
    "Pipe",
    "Identity",
    ["Slice", null, [4]],
  ])
}
