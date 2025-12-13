///|
/// Helper to run jq queries
fn run_jq(query : String, input : String) -> Result[Array[Json], String] {
  let expr = @parser.parse(query) catch { e => return Err(e.to_string()) }
  let json = @json.parse(input) catch { e => return Err(e.to_string()) }
  let results = eval(expr, json).collect() catch {
    e => return Err(e.to_string())
  }
  Ok(results)
}

///|
test "split function" {
  let result = run_jq(".name | split(\",\")", "{\"name\":\"a,b,c\"}")
  inspect(
    result,
    content="Ok([Array([String(\"a\"), String(\"b\"), String(\"c\")])])",
  )
}

///|
test "join function" {
  let result = run_jq(".items | join(\",\")", "{\"items\":[\"a\",\"b\",\"c\"]}")
  inspect(
    result,
    content=(
      #|Ok([String("a,b,c")])
    ),
  )
}

///|
test "has function" {
  let result = run_jq("has(\"name\")", "{\"name\":\"John\",\"age\":30}")
  inspect(result, content="Ok([True])")
  let result2 = run_jq("has(\"missing\")", "{\"name\":\"John\"}")
  inspect(result2, content="Ok([False])")
}

///|
test "contains function" {
  let result = run_jq(
    ".text | contains(\"hello\")", "{\"text\":\"hello world\"}",
  )
  inspect(result, content="Ok([True])")
}

///|
test "startswith function" {
  let result = run_jq(
    ".text | startswith(\"hello\")", "{\"text\":\"hello world\"}",
  )
  inspect(result, content="Ok([True])")
}

///|
test "endswith function" {
  let result = run_jq(
    ".text | endswith(\"world\")", "{\"text\":\"hello world\"}",
  )
  inspect(result, content="Ok([True])")
}

///|
test "to_entries function" {
  let result = run_jq("to_entries", "{\"a\":1,\"b\":2}")
  inspect(
    result,
    content=(
      #|Ok([Array([Object({"key": String("a"), "value": Number(1)}), Object({"key": String("b"), "value": Number(2)})])])
    ),
  )
}

///|
test "from_entries function" {
  let result = run_jq(
    "from_entries", "[{\"key\":\"a\",\"value\":1},{\"key\":\"b\",\"value\":2}]",
  )
  inspect(
    result,
    content=(
      #|Ok([Object({"a": Number(1), "b": Number(2)})])
    ),
  )
}

///|
test "range function" {
  let result = run_jq("range(5)", "null")
  inspect(
    result,
    content="Ok([Number(0), Number(1), Number(2), Number(3), Number(4)])",
  )
}

///|
test "first function" {
  let result = run_jq("first", "[1,2,3]")
  inspect(result, content="Ok([Number(1)])")
}

///|
test "last function" {
  let result = run_jq("last", "[1,2,3]")
  inspect(result, content="Ok([Number(3)])")
}

///|
test "any function" {
  let result = run_jq("any", "[true,false,false]")
  inspect(result, content="Ok([True])")
  let result2 = run_jq("any", "[false,false]")
  inspect(result2, content="Ok([False])")
}

///|
test "all function" {
  let result = run_jq("all", "[true,true,true]")
  inspect(result, content="Ok([True])")
  let result2 = run_jq("all", "[true,false,true]")
  inspect(result2, content="Ok([False])")
}

///|
test "round function" {
  let result = run_jq("round", "3.7")
  inspect(result, content="Ok([Number(4)])")
}

///|
test "ceil function" {
  let result = run_jq("ceil", "3.2")
  inspect(result, content="Ok([Number(4)])")
}

///|
test "abs function" {
  let result = run_jq("abs", "-5")
  inspect(result, content="Ok([Number(5)])")
}

///|
test "sort_by function" {
  let result = run_jq(
    "sort_by(.age)", "[{\"name\":\"Bob\",\"age\":30},{\"name\":\"Alice\",\"age\":25}]",
  )
  inspect(
    result,
    content=(
      #|Ok([Array([Object({"name": String("Alice"), "age": Number(25)}), Object({"name": String("Bob"), "age": Number(30)})])])
    ),
  )
}

///|
test "group_by function" {
  let result = run_jq(
    "group_by(.type)", "[{\"name\":\"a\",\"type\":\"X\"},{\"name\":\"b\",\"type\":\"Y\"},{\"name\":\"c\",\"type\":\"X\"}]",
  )
  inspect(
    result,
    content=(
      #|Ok([Array([Array([Object({"name": String("a"), "type": String("X")}), Object({"name": String("c"), "type": String("X")})]), Array([Object({"name": String("b"), "type": String("Y")})])])])
    ),
  )
}

///|
test "reduce expression" {
  let result = run_jq("reduce .[] as $x (0; . + $x)", "[1,2,3,4,5]")
  inspect(
    result,
    content=(
      #|Ok([Number(15)])
    ),
  )
}

///|
test "as expression" {
  let result = run_jq(".a as $x | .b + $x", "{\"a\":10,\"b\":5}")
  inspect(result, content="Ok([Number(15)])")
}
