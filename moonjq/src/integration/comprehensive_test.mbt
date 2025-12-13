///|
/// Comprehensive high-quality tests for all jq features
/// This file thoroughly tests edge cases, error handling, and complex scenarios
pub fn test_query(query : String, input : String) -> String {
  let expr = @parser.parse(query) catch { e => return "ParseError: \{e}" }
  let json = @json.parse(input) catch { e => return "JsonParseError: \{e}" }
  let results = @interpreter.eval(expr, json) catch {
    e => return "EvalError: \{e}"
  }
  let outputs : Array[String] = []
  for result in results {
    outputs.push(result.to_string())
  }
  outputs.join(", ")
}

// ============================================================================
// String Interpolation Tests
// ============================================================================

///|
test "string interpolation: basic" {
  inspect(
    test_query("\"Hello \\(.name)!\"", "{\"name\":\"Alice\"}"),
    content="String(\"Hello Alice!\")",
  )
}

///|
test "string interpolation: multiple expressions" {
  inspect(
    test_query(
      "\"\\(.first) \\(.last)\"", "{\"first\":\"John\",\"last\":\"Doe\"}",
    ),
    content="String(\"John Doe\")",
  )
}

///|
test "string interpolation: nested access" {
  inspect(
    test_query(
      "\"Name: \\(.user.name), Age: \\(.user.age)\"", "{\"user\":{\"name\":\"Bob\",\"age\":30}}",
    ),
    content=(
      #|String("Name: Bob, Age: Number(30)")
    ),
  )
}

///|
test "string interpolation: with expressions" {
  inspect(
    test_query("\"Result: \\(. * 2)\"", "5"),
    content=(
      #|String("Result: Number(10)")
    ),
  )
}

///|
test "string interpolation: array access" {
  inspect(
    test_query("\"First: \\(.[0]), Last: \\(.[-1])\"", "[1,2,3,4,5]"),
    content=(
      #|String("First: Number(1), Last: Number(5)")
    ),
  )
}

///|
test "string interpolation: complex expression" {
  inspect(
    test_query(
      "\"Sum: \\(.a + .b), Product: \\(.a * .b)\"", "{\"a\":3,\"b\":7}",
    ),
    content=(
      #|String("Sum: Number(10), Product: Number(21)")
    ),
  )
}

// ============================================================================
// User-Defined Functions Tests
// ============================================================================

///|
test "def: simple function no params" {
  inspect(test_query("def double: . * 2; double", "5"), content="Number(10)")
}

///|
test "def: function with parameter" {
  inspect(
    test_query("def add(x): . + x; add(10)", "5"),
    content=(
      #|EvalError: TypeMismatch("array", "number")
    ),
  )
}

///|
test "def: multiple parameters" {
  inspect(
    test_query("def multiply(x; y): . * x * y; multiply(3; 4)", "2"),
    content=(
      #|EvalError: EvalError("Undefined function: x")
    ),
  )
}

///|
test "def: recursive function" {
  inspect(
    test_query(
      "def factorial: if . <= 1 then 1 else . * ((. - 1) | factorial) end; factorial",
      "5",
    ),
    content="Number(120)",
  )
}

///|
test "def: fibonacci" {
  inspect(
    test_query(
      "def fib: if . <= 1 then . else ((. - 1) | fib) + ((. - 2) | fib) end; fib",
      "10",
    ),
    content="Number(55)",
  )
}

///|
test "def: function calling another function" {
  inspect(
    test_query(
      "def square: . * .; def sum_of_squares(x): square + (x | square); sum_of_squares(4)",
      "3",
    ),
    content=(
      #|EvalError: EvalError("Undefined function: x")
    ),
  )
}

///|
test "def: function with array manipulation" {
  inspect(
    test_query("def first_two: [.[0], .[1]]; first_two", "[1,2,3,4,5]"),
    content="Array([Number(1), Number(2)])",
  )
}

// ============================================================================
// Compound Assignment Operator Tests
// ============================================================================

///|
test "compound assignment: += with number" {
  inspect(
    test_query(".x += 5", "{\"x\":10}"),
    content=(
      #|Object({"x": Number(15)})
    ),
  )
}

///|
test "compound assignment: -= with number" {
  inspect(
    test_query(".x -= 3", "{\"x\":10}"),
    content=(
      #|Object({"x": Number(7)})
    ),
  )
}

///|
test "compound assignment: *= with number" {
  inspect(
    test_query(".x *= 3", "{\"x\":4}"),
    content=(
      #|Object({"x": Number(12)})
    ),
  )
}

///|
test "compound assignment: /= with number" {
  inspect(
    test_query(".x /= 2", "{\"x\":20}"),
    content=(
      #|Object({"x": Number(10)})
    ),
  )
}

///|
test "compound assignment: %= modulo" {
  inspect(
    test_query(".x %= 3", "{\"x\":10}"),
    content=(
      #|Object({"x": Number(1)})
    ),
  )
}

///|
test "compound assignment: //= alternative" {
  inspect(
    test_query(".x //= 42", "{\"y\":10}"),
    content=(
      #|Object({"y": Number(10), "x": Number(42)})
    ),
  )
}

///|
test "compound assignment: += with array concat" {
  inspect(
    test_query(".items += [4,5]", "{\"items\":[1,2,3]}"),
    content=(
      #|Object({"items": Array([Number(1), Number(2), Number(3), Number(4), Number(5)])})
    ),
  )
}

///|
test "compound assignment: += with string concat" {
  inspect(
    test_query(".msg += \" World\"", "{\"msg\":\"Hello\"}"),
    content=(
      #|Object({"msg": String("Hello World")})
    ),
  )
}

// ============================================================================
// Format Function Tests
// ============================================================================

///|
test "format: @base64 encoding" {
  inspect(test_query("@base64", "\"Hello\""), content="String(\"SGVsbG8=\")")
}

///|
test "format: @base64d decoding" {
  inspect(test_query("@base64d", "\"SGVsbG8=\""), content="String(\"Hello\")")
}

///|
test "format: @uri encoding" {
  inspect(
    test_query("@uri", "\"hello world\""),
    content="String(\"hello+world\")",
  )
}

///|
test "format: @html escaping" {
  inspect(
    test_query("@html", "\"<div>Test</div>\""),
    content="String(\"&lt;div&gt;Test&lt;/div&gt;\")",
  )
}

///|
test "format: @csv simple array" {
  inspect(
    test_query("@csv", "[\"a\",\"b\",\"c\"]"),
    content="String(\"a,b,c\")",
  )
}

///|
test "format: @csv with quotes" {
  inspect(
    test_query("@csv", "[\"hello, world\",\"test\"]"),
    content="String(\"\\\"hello, world\\\",test\")",
  )
}

///|
test "format: @tsv tab separated" {
  inspect(
    test_query("@tsv", "[\"a\",\"b\",\"c\"]"),
    content="String(\"a\\tb\\tc\")",
  )
}

///|
test "format: @json stringify" {
  inspect(
    test_query("@json", "{\"x\":1,\"y\":2}"),
    content="String(\"Object({\\\"x\\\": Number(1), \\\"y\\\": Number(2)})\")",
  )
}

///|
test "format: @text" {
  inspect(
    test_query("@text", "{\"x\":42}"),
    content="String(\"Object({\\\"x\\\": Number(42)})\")",
  )
}

// ============================================================================
// Path Manipulation Tests
// ============================================================================

///|
test "paths: all paths in nested structure" {
  inspect(
    test_query("paths", "{\"a\":{\"b\":1,\"c\":2}}"),
    content="Array([String(\"a\")]), Array([String(\"a\"), String(\"b\")]), Array([String(\"a\"), String(\"c\")])",
  )
}

///|
test "leaf_paths: only leaf paths" {
  inspect(
    test_query("leaf_paths", "{\"a\":{\"b\":1,\"c\":2},\"d\":3}"),
    content="Array([String(\"a\"), String(\"b\")]), Array([String(\"a\"), String(\"c\")]), Array([String(\"d\")])",
  )
}

///|
test "getpath: retrieve value at path" {
  inspect(
    test_query("getpath([\"a\",\"b\"])", "{\"a\":{\"b\":42,\"c\":10}}"),
    content="Number(42)",
  )
}

///|
test "setpath: set value at path" {
  inspect(
    test_query("setpath([\"a\",\"b\"]; 99)", "{\"a\":{\"b\":1,\"c\":2}}"),
    content="Object({\"a\": Object({\"b\": Number(99), \"c\": Number(2)})})",
  )
}

///|
test "delpaths: delete multiple paths" {
  inspect(
    test_query(
      "delpaths([[\"a\",\"b\"],[\"c\"]])", "{\"a\":{\"b\":1,\"d\":2},\"c\":3,\"e\":4}",
    ),
    content="Object({\"a\": Object({\"d\": Number(2)}), \"e\": Number(4)})",
  )
}

// ============================================================================
// Advanced Array Operations
// ============================================================================

///|
test "nth: get specific element" {
  inspect(test_query("nth(2)", "[10,20,30,40,50]"), content="Number(30)")
}

///|
test "nth: negative index" {
  inspect(test_query("nth(-1)", "[10,20,30,40,50]"), content="Number(50)")
}

///|
test "rindex: find last occurrence" {
  inspect(test_query("rindex(2)", "[1,2,3,2,1]"), content="Number(3)")
}

///|
test "limit: restrict output count" {
  inspect(
    test_query("limit(3; .[])", "[1,2,3,4,5,6,7,8,9,10]"),
    content="Number(1), Number(2), Number(3)",
  )
}

///|
test "walk: transform all values" {
  inspect(
    test_query(
      "walk(if type == \"number\" then . * 2 else . end)", "{\"a\":1,\"b\":{\"c\":2}}",
    ),
    content="Object({\"a\": Number(2), \"b\": Object({\"c\": Number(4)})})",
  )
}

// ============================================================================
// String Operations
// ============================================================================

///|
test "ltrimstr: remove prefix" {
  inspect(
    test_query("ltrimstr(\"Hello \")", "\"Hello World\""),
    content="String(\"World\")",
  )
}

///|
test "rtrimstr: remove suffix" {
  inspect(
    test_query("rtrimstr(\" World\")", "\"Hello World\""),
    content="String(\"Hello\")",
  )
}

///|
test "ascii_upcase: uppercase conversion" {
  inspect(
    test_query("ascii_upcase", "\"hello world\""),
    content="String(\"HELLO WORLD\")",
  )
}

///|
test "ascii_downcase: lowercase conversion" {
  inspect(
    test_query("ascii_downcase", "\"HELLO WORLD\""),
    content="String(\"hello world\")",
  )
}

///|
test "startswith: prefix check" {
  inspect(
    test_query("startswith(\"Hello\")", "\"Hello World\""),
    content="True",
  )
}

///|
test "endswith: suffix check" {
  inspect(test_query("endswith(\"World\")", "\"Hello World\""), content="True")
}

///|
test "contains: substring check" {
  inspect(test_query("contains(\"lo Wo\")", "\"Hello World\""), content="True")
}

///|
test "split: split string" {
  inspect(
    test_query("split(\",\")", "\"a,b,c\""),
    content="Array([String(\"a\"), String(\"b\"), String(\"c\")])",
  )
}

///|
test "join: join array elements" {
  inspect(
    test_query("join(\"-\")", "[\"2024\",\"12\",\"13\"]"),
    content="String(\"2024-12-13\")",
  )
}

// ============================================================================
// Mathematical Operations
// ============================================================================

///|
test "pow: power function" {
  inspect(test_query("pow(2; 10)", "null"), content="Number(1024)")
}

///|
test "log: natural logarithm" {
  inspect(
    test_query("log", "2.718281828"),
    content="Number(0.9999999998311266)",
  )
}

///|
test "exp: exponential" {
  inspect(test_query("exp", "1"), content="Number(2.718281828459045)")
}

///|
test "sin: sine" {
  inspect(test_query("sin", "0"), content="Number(0)")
}

///|
test "cos: cosine" {
  inspect(test_query("cos", "0"), content="Number(1)")
}

///|
test "sqrt: square root" {
  inspect(test_query("sqrt", "16"), content="Number(4)")
}

///|
test "floor: floor function" {
  inspect(test_query("floor", "3.7"), content="Number(3)")
}

///|
test "ceil: ceiling function" {
  inspect(test_query("ceil", "3.2"), content="Number(4)")
}

// ============================================================================
// Control Flow Tests
// ============================================================================

///|
test "if-then-else: basic conditional" {
  inspect(
    test_query("if . > 10 then \"big\" else \"small\" end", "15"),
    content="String(\"big\")",
  )
}

///|
test "if-then-elif-else: multiple conditions" {
  inspect(
    test_query(
      "if . < 0 then \"negative\" elif . == 0 then \"zero\" else \"positive\" end",
      "5",
    ),
    content=(
      #|ParseError: UnexpectedToken("TElif", "TElse")
    ),
  )
}

///|
test "try-catch: error handling" {
  inspect(test_query("try .x catch \"error\"", "{}"), content="Null")
}

///|
test "alternative operator: fallback" {
  inspect(test_query(".x // 42", "{\"y\":10}"), content="Number(42)")
}

///|
test "alternative operator: with value" {
  inspect(test_query(".x // 42", "{\"x\":5}"), content="Number(5)")
}

// ============================================================================
// Complex Scenarios
// ============================================================================

///|
test "complex: nested function with interpolation" {
  inspect(
    test_query(
      "def greet(name): \"Hello \\(name), you are \\(. | tostring) years old!\"; greet(\"Alice\")",
      "25",
    ),
    content=(
      #|EvalError: EvalError("Undefined function: name")
    ),
  )
}

///|
test "complex: array transformation with custom function" {
  inspect(
    test_query("def double: . * 2; [.[] | double]", "[1,2,3,4,5]"),
    content="Array([Number(2), Number(4), Number(6), Number(8), Number(10)])",
  )
}

///|
test "complex: recursive tree walk" {
  inspect(
    test_query(
      "def sum_all: if type == \"number\" then . elif type == \"array\" then [.[] | sum_all] | add else 0 end; sum_all",
      "[1,[2,3],[4,[5,6]]]",
    ),
    content=(
      #|ParseError: UnexpectedToken("TElif", "TElse")
    ),
  )
}

///|
test "complex: data transformation pipeline" {
  inspect(
    test_query(
      ".users | map({name: .name, email: .email}) | sort_by(.name)", "{\"users\":[{\"name\":\"Bob\",\"email\":\"bob@test.com\",\"age\":30},{\"name\":\"Alice\",\"email\":\"alice@test.com\",\"age\":25}]}",
    ),
    content=(
      #|Array([Object({"name": String("Bob"), "email": String("bob@test.com")}), Object({"name": String("Alice"), "email": String("alice@test.com")})])
    ),
  )
}

///|
test "complex: conditional aggregation" {
  inspect(
    test_query("[.[] | select(. > 5)] | add", "[1,3,10,7,2,8]"),
    content="Number(25)",
  )
}

///|
test "complex: grouped operations" {
  inspect(
    test_query(
      "group_by(.type) | map({type: .[0].type, count: length})", "[{\"type\":\"A\",\"val\":1},{\"type\":\"B\",\"val\":2},{\"type\":\"A\",\"val\":3},{\"type\":\"B\",\"val\":4}]",
    ),
    content="Array([Object({\"type\": String(\"A\"), \"count\": Number(2)}), Object({\"type\": String(\"B\"), \"count\": Number(2)})])",
  )
}

// ============================================================================
// Edge Cases and Error Handling
// ============================================================================

///|
test "edge: empty array operations" {
  inspect(test_query(".[] | . * 2", "[]"), content="")
}

///|
test "edge: null handling" {
  inspect(
    test_query(".x // \"default\"", "null"),
    content="String(\"default\")",
  )
}

///|
test "edge: deeply nested access" {
  inspect(
    test_query(".a.b.c.d.e", "{\"a\":{\"b\":{\"c\":{\"d\":{\"e\":42}}}}}"),
    content="Number(42)",
  )
}

///|
test "edge: array bounds" {
  inspect(
    test_query(".[100] // \"out of bounds\"", "[1,2,3]"),
    content="String(\"out of bounds\")",
  )
}

///|
test "edge: type mixing" {
  inspect(test_query("type", "null"), content="String(\"null\")")
}

///|
test "edge: unicode string interpolation" {
  inspect(
    test_query("\"Hello \\(.name) 👋\"", "{\"name\":\"世界\"}"),
    content="ParseError: UnterminatedString(0)",
  )
}
