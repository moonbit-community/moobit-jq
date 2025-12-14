///|
/// Integration helper to parse and eval
fn jq(query : String, input : String) -> Array[Json] raise {
  let expr = @parser.parse(query)
  let json = @json.parse(input)
  eval(expr, json).collect()
}

///|
/// Test basic identity and field access
test "integration: basic queries" {
  @json.inspect(jq(".", "42"), content=[42])
  @json.inspect(jq(".foo", "{\"foo\": \"bar\"}"), content=["bar"])
  @json.inspect(jq(".a.b", "{\"a\": {\"b\": 123}}"), content=[123])
}

///|
/// Test array operations
test "integration: array operations" {
  @json.inspect(jq(".[]", "[1,2,3]"), content=[1, 2, 3])
  @json.inspect(jq(".[1]", "[10,20,30]"), content=[20])
  @json.inspect(jq(".[-1]", "[10,20,30]"), content=[30])
  @json.inspect(jq(".[1:3]", "[1,2,3,4,5]"), content=[[2, 3]])
}

///|
/// Test pipe and comma
test "integration: pipe and comma" {
  @json.inspect(jq(". | . + 1", "5"), content=[6])
  @json.inspect(jq(".a | .b", "{\"a\": {\"b\": 42}}"), content=[42])
  @json.inspect(jq(".a, .b", "{\"a\": 1, \"b\": 2}"), content=[1, 2])
}

///|
/// Test arithmetic
test "integration: arithmetic" {
  @json.inspect(jq("1 + 2", "null"), content=[3])
  @json.inspect(jq("10 - 3", "null"), content=[7])
  @json.inspect(jq("6 * 7", "null"), content=[42])
  @json.inspect(jq("20 / 4", "null"), content=[5])
  @json.inspect(jq("17 % 5", "null"), content=[2])
}

///|
/// Test string operations
test "integration: strings" {
  @json.inspect(jq("\"hello\" + \" \" + \"world\"", "null"), content=[
    "hello world",
  ])
  @json.inspect(
    jq(".first + .last", "{\"first\": \"Hello\", \"last\": \" MoonBit\"}"),
    content=["Hello MoonBit"],
  )
}

///|
/// Test comparisons
test "integration: comparisons" {
  @json.inspect(jq("1 < 2", "null"), content=[true])
  @json.inspect(jq("5 > 10", "null"), content=[false])
  @json.inspect(jq("3 == 3", "null"), content=[true])
  @json.inspect(jq("4 != 5", "null"), content=[true])
}

///|
/// Test array construction
test "integration: array construction" {
  @json.inspect(jq("[.a, .b, .c]", "{\"a\": 1, \"b\": 2, \"c\": 3}"), content=[
    [1, 2, 3],
  ])
  @json.inspect(jq("[.[] | . * 2]", "[1,2,3]"), content=[[2, 4, 6]])
}

///|
/// Test object construction
test "integration: object construction" {
  @json.inspect(jq("{x: .a, y: .b}", "{\"a\": 10, \"b\": 20}"), content=[
    { "x": 10, "y": 20 },
  ])
  @json.inspect(jq("{result: (. + 1)}", "5"), content=[{ "result": 6 }])
}

///|
/// Test built-ins: length, keys, type
test "integration: built-in functions" {
  @json.inspect(jq("length", "[1,2,3,4,5]"), content=[5])
  @json.inspect(jq("length", "\"hello\""), content=[5])
  @json.inspect(jq("keys", "{\"b\": 1, \"a\": 2}"), content=[["b", "a"]])
  @json.inspect(jq("type", "42"), content=["number"])
  @json.inspect(jq("type", "\"hi\""), content=["string"])
}

///|
/// Test control flow
test "integration: control flow" {
  @json.inspect(jq("if . > 5 then \"big\" else \"small\" end", "10"), content=[
    "big",
  ])
  @json.inspect(jq("if . > 5 then \"big\" else \"small\" end", "2"), content=[
    "small",
  ])
}

///|
/// Test complex real-world query
test "integration: filter and transform" {
  let data : String =
    #|{
    #|  "users": [
    #|    { "name": "Alice", "age": 25, "active": true },
    #|    { "name": "Bob", "age": 15, "active": false },
    #|    { "name": "Charlie", "age": 30, "active": true }
    #|  ]
    #|}
  // Filter users who are active
  @json.inspect(jq(".users | .[] | select(.active) | .name", data), content=[
    "Alice", "Charlie",
  ])
}

///|
/// Test optional operator
test "integration: optional operator" {
  @json.inspect(jq(".a.b.c?", "{}"), content=[null])
  @json.inspect(jq(".x?", "{\"x\": 42}"), content=[42])
}

///|
/// Test alternative operator
test "integration: alternative operator" {
  @json.inspect(jq(".a // .b", "{\"a\": null, \"b\": 10}"), content=[10])
  @json.inspect(jq(".a // .b", "{\"a\": 5, \"b\": 10}"), content=[5])
  @json.inspect(jq(".missing // \"default\"", "{}"), content=["default"])
}

///|
/// Test recursive descent
test "integration: recursive descent" {
  let data : String =
    #|{
    #|  "a": { "b": 1, "c": 2 }
    #|}
  let results = jq("..", data)
  // Should yield the input object first
  @json.inspect(results[0], content={ "a": { "b": 1, "c": 2 } })
}

///|
/// Test error handling
test "integration: error propagation" {
  // Division by zero should raise error
  let result = try? jq("1 / 0", "null")
  assert_true(result is Err(_))
}

///|
/// Test map function
test "integration: map function" {
  @json.inspect(jq("map(. + 10)", "[1, 2, 3]"), content=[[11, 12, 13]])
  @json.inspect(jq("map(. * 2)", "[5, 10, 15]"), content=[[10, 20, 30]])
}

///|
/// Test select function
test "integration: select function" {
  @json.inspect(jq(".[] | select(. > 3)", "[1, 2, 3, 4, 5]"), content=[4, 5])
  @json.inspect(jq(".[] | select(. < 0)", "[1, 2, 3]"), content=[])
}

///|
/// Test array functions
test "integration: array functions" {
  @json.inspect(jq("sort", "[3, 1, 4, 1, 5, 9, 2, 6]"), content=[
    [1, 1, 2, 3, 4, 5, 6, 9],
  ])
  @json.inspect(jq("reverse", "[1, 2, 3]"), content=[[3, 2, 1]])
  @json.inspect(jq("unique", "[1, 2, 1, 3, 2]"), content=[[1, 2, 3]])
}

///|
/// Test numeric functions
test "integration: numeric functions" {
  @json.inspect(jq("add", "[1, 2, 3, 4, 5]"), content=[15])
  @json.inspect(jq("min", "[5, 2, 8, 1]"), content=[1])
  @json.inspect(jq("max", "[5, 2, 8, 1]"), content=[8])
  @json.inspect(jq("floor", "3.7"), content=[3])
  @json.inspect(jq("sqrt", "16"), content=[4])
}

///|
/// Test complex nested query
test "integration: complex nested query" {
  let data : String =
    #|{
    #|  "store": {
    #|    "books": [
    #|      { "title": "Book A", "price": 10 },
    #|      { "title": "Book B", "price": 15 }
    #|    ]
    #|  }
    #|}
  @json.inspect(jq(".store.books | .[] | .title", data), content=[
    "Book A", "Book B",
  ])
  @json.inspect(jq(".store.books | map(.price)", data), content=[[10, 15]])
}

///|
/// Test logical operators
test "integration: logical operators" {
  @json.inspect(jq("true and false", "null"), content=[false])
  @json.inspect(jq("true or false", "null"), content=[true])
  @json.inspect(jq("not", "true"), content=[false])
  @json.inspect(jq("not", "false"), content=[true])
}
