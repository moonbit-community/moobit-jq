///|
/// Integration helper to parse and eval
fn jq(query : String, input : String) -> String raise {
  let expr = @parser.parse(query)
  let json = @json.parse(input)
  let results = @interpreter.eval(expr, json).collect()
  // Format results as newline-separated JSON
  results.map(fn(j) { j.to_string() }).join("\n")
}

///|
/// Test basic identity and field access
test "integration: basic queries" {
  inspect(jq(".", "42"), content="Number(42)")
  inspect(
    jq(".foo", "{\"foo\": \"bar\"}"),
    content=(
      #|String("bar")
    ),
  )
  inspect(jq(".a.b", "{\"a\": {\"b\": 123}}"), content="Number(123)")
}

///|
/// Test array operations
test "integration: array operations" {
  inspect(
    jq(".[]", "[1,2,3]"),
    content=(
      #|Number(1)
      #|Number(2)
      #|Number(3)
    ),
  )
  inspect(jq(".[1]", "[10,20,30]"), content="Number(20)")
  inspect(jq(".[-1]", "[10,20,30]"), content="Number(30)")
  inspect(jq(".[1:3]", "[1,2,3,4,5]"), content="Array([Number(2), Number(3)])")
}

///|
/// Test pipe and comma
test "integration: pipe and comma" {
  inspect(jq(". | . + 1", "5"), content="Number(6)")
  inspect(jq(".a | .b", "{\"a\": {\"b\": 42}}"), content="Number(42)")
  inspect(
    jq(".a, .b", "{\"a\": 1, \"b\": 2}"),
    content=(
      #|Number(1)
      #|Number(2)
    ),
  )
}

///|
/// Test arithmetic
test "integration: arithmetic" {
  inspect(jq("1 + 2", "null"), content="Number(3)")
  inspect(jq("10 - 3", "null"), content="Number(7)")
  inspect(jq("6 * 7", "null"), content="Number(42)")
  inspect(jq("20 / 4", "null"), content="Number(5)")
  inspect(jq("17 % 5", "null"), content="Number(2)")
}

///|
/// Test string operations
test "integration: strings" {
  inspect(
    jq("\"hello\" + \" \" + \"world\"", "null"),
    content=(
      #|String("hello world")
    ),
  )
  inspect(
    jq(".first + .last", "{\"first\": \"Hello\", \"last\": \" MoonBit\"}"),
    content=(
      #|String("Hello MoonBit")
    ),
  )
}

///|
/// Test comparisons
test "integration: comparisons" {
  inspect(jq("1 < 2", "null"), content="True")
  inspect(jq("5 > 10", "null"), content="False")
  inspect(jq("3 == 3", "null"), content="True")
  inspect(jq("4 != 5", "null"), content="True")
}

///|
/// Test array construction
test "integration: array construction" {
  inspect(
    jq("[.a, .b, .c]", "{\"a\": 1, \"b\": 2, \"c\": 3}"),
    content="Array([Number(1), Number(2), Number(3)])",
  )
  inspect(
    jq("[.[] | . * 2]", "[1,2,3]"),
    content="Array([Number(2), Number(4), Number(6)])",
  )
}

///|
/// Test object construction
test "integration: object construction" {
  inspect(
    jq("{x: .a, y: .b}", "{\"a\": 10, \"b\": 20}"),
    content=(
      #|Object({"x": Number(10), "y": Number(20)})
    ),
  )
  inspect(
    jq("{result: (. + 1)}", "5"),
    content=(
      #|Object({"result": Number(6)})
    ),
  )
}

///|
/// Test built-ins: length, keys, type
test "integration: built-in functions" {
  inspect(jq("length", "[1,2,3,4,5]"), content="Number(5)")
  inspect(jq("length", "\"hello\""), content="Number(5)")
  inspect(
    jq("keys", "{\"b\": 1, \"a\": 2}"),
    content=(
      #|Array([String("b"), String("a")])
    ),
  )
  inspect(
    jq("type", "42"),
    content=(
      #|String("number")
    ),
  )
  inspect(
    jq("type", "\"hi\""),
    content=(
      #|String("string")
    ),
  )
}

///|
/// Test control flow
test "integration: control flow" {
  inspect(
    jq("if . > 5 then \"big\" else \"small\" end", "10"),
    content=(
      #|String("big")
    ),
  )
  inspect(
    jq("if . > 5 then \"big\" else \"small\" end", "2"),
    content=(
      #|String("small")
    ),
  )
}

///|
/// Test complex real-world query
test "integration: filter and transform" {
  let data = "{\"users\": [{\"name\": \"Alice\", \"age\": 25, \"active\": true}, {\"name\": \"Bob\", \"age\": 15, \"active\": false}, {\"name\": \"Charlie\", \"age\": 30, \"active\": true}]}"
  // Filter users who are active
  inspect(
    jq(".users | .[] | select(.active) | .name", data),
    content=(
      #|String("Alice")
      #|String("Charlie")
    ),
  )
}

///|
/// Test optional operator
test "integration: optional operator" {
  inspect(jq(".a.b.c?", "{}"), content="Null")
  inspect(jq(".x?", "{\"x\": 42}"), content="Number(42)")
}

///|
/// Test alternative operator
test "integration: alternative operator" {
  inspect(jq(".a // .b", "{\"a\": null, \"b\": 10}"), content="Number(10)")
  inspect(jq(".a // .b", "{\"a\": 5, \"b\": 10}"), content="Number(5)")
  inspect(
    jq(".missing // \"default\"", "{}"),
    content=(
      #|String("default")
    ),
  )
}

///|
/// Test recursive descent
test "integration: recursive descent" {
  let data = "{\"a\": {\"b\": 1, \"c\": 2}}"
  let result = jq("..", data)
  // Should yield the input object, nested objects, and leaf values
  inspect(result.contains("\"a\""), content="true")
}

///|
/// Test error handling
test "integration: error propagation" {
  // Division by zero should raise error
  let result = try? jq("1 / 0", "null")
  inspect(result is Err(_), content="true")
}

///|
/// Test map function
test "integration: map function" {
  inspect(
    jq("map(. + 10)", "[1, 2, 3]"),
    content="Array([Number(11), Number(12), Number(13)])",
  )
  inspect(
    jq("map(. * 2)", "[5, 10, 15]"),
    content="Array([Number(10), Number(20), Number(30)])",
  )
}

///|
/// Test select function
test "integration: select function" {
  inspect(
    jq(".[] | select(. > 3)", "[1, 2, 3, 4, 5]"),
    content=(
      #|Number(4)
      #|Number(5)
    ),
  )
  inspect(jq(".[] | select(. < 0)", "[1, 2, 3]"), content="")
}

///|
/// Test array functions
test "integration: array functions" {
  inspect(
    jq("sort", "[3, 1, 4, 1, 5, 9, 2, 6]"),
    content="Array([Number(1), Number(1), Number(2), Number(3), Number(4), Number(5), Number(6), Number(9)])",
  )
  inspect(
    jq("reverse", "[1, 2, 3]"),
    content="Array([Number(3), Number(2), Number(1)])",
  )
  inspect(
    jq("unique", "[1, 2, 1, 3, 2]"),
    content="Array([Number(1), Number(2), Number(3)])",
  )
}

///|
/// Test numeric functions
test "integration: numeric functions" {
  inspect(jq("add", "[1, 2, 3, 4, 5]"), content="Number(15)")
  inspect(jq("min", "[5, 2, 8, 1]"), content="Number(1)")
  inspect(jq("max", "[5, 2, 8, 1]"), content="Number(8)")
  inspect(jq("floor", "3.7"), content="Number(3)")
  inspect(jq("sqrt", "16"), content="Number(4)")
}

///|
/// Test complex nested query
test "integration: complex nested query" {
  let data = "{\"store\": {\"books\": [{\"title\": \"Book A\", \"price\": 10}, {\"title\": \"Book B\", \"price\": 15}]}}"
  inspect(
    jq(".store.books | .[] | .title", data),
    content=(
      #|String("Book A")
      #|String("Book B")
    ),
  )
  inspect(
    jq(".store.books | map(.price)", data),
    content="Array([Number(10), Number(15)])",
  )
}

///|
/// Test logical operators
test "integration: logical operators" {
  inspect(jq("true and false", "null"), content="False")
  inspect(jq("true or false", "null"), content="True")
  inspect(jq("not", "true"), content="False")
  inspect(jq("not", "false"), content="True")
}
