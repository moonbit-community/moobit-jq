///|
/// Test helper to check if features are missing
fn test_feature(query : String, input : String) -> String {
  let expr = @parser.parse(query) catch { e => return "ParseError: \{e}" }
  let json = @json.parse(input) catch { e => return "JsonError: \{e}" }
  let results = @interpreter.eval(expr, json).collect() catch {
    e => return "EvalError: \{e}"
  }
  results.map(fn(j) { j.to_string() }).join("\n")
}

///|
test "missing: values function" {
  inspect(
    test_feature("values", "[1,2,null,3]"),
    content="Array([Number(1), Number(2), Null, Number(3)])",
  )
}

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
test "missing: nth(n)" {
  inspect(test_feature("nth(1)", "[10,20,30]"), content="Number(20)")
}

///|
test "missing: limit(n; expr)" {
  inspect(
    test_feature("limit(2; .[])", "[1,2,3,4,5]"),
    content=(
      #|Number(1)
      #|Number(2)
    ),
  )
}

///|
// Temporarily disabled
// test "missing: until(cond; update)" {
//   inspect(test_feature("1 | until(. > 5; . + 1)", "null"), content="")
// }

///|
// Temporarily disabled - causes infinite loop
// test "missing: while(cond; update)" {
//   inspect(test_feature("1 | while(. < 5; . + 1)", "null"), content="")
// }

///|
test "missing: rindex" {
  inspect(test_feature("[1,2,3,2,1] | rindex(2)", "null"), content="Number(3)")
}

///|
test "missing: paths" {
  inspect(
    test_feature("paths", "{\"a\":{\"b\":1},\"c\":[2,3]}"),
    content=(
      #|Array([String("a")])
      #|Array([String("a"), String("b")])
      #|Array([String("c")])
      #|Array([String("c"), Number(0)])
      #|Array([String("c"), Number(1)])
    ),
  )
}

///|
test "missing: leaf_paths" {
  inspect(
    test_feature("leaf_paths", "{\"a\":{\"b\":1},\"c\":[2,3]}"),
    content=(
      #|Array([String("a"), String("b")])
      #|Array([String("c"), Number(0)])
      #|Array([String("c"), Number(1)])
    ),
  )
}

///|
test "missing: getpath" {
  inspect(
    test_feature("getpath([\"a\",\"b\"])", "{\"a\":{\"b\":42}}"),
    content="Number(42)",
  )
}

///|
test "missing: setpath" {
  inspect(
    test_feature("setpath([\"a\",\"b\"]; 99)", "{\"a\":{\"b\":42}}"),
    content=(
      #|Object({"a": Object({"b": Number(99)})})
    ),
  )
}

///|
test "missing: delpaths" {
  inspect(
    test_feature("delpaths([[\"a\",\"b\"]])", "{\"a\":{\"b\":42,\"c\":1}}"),
    content=(
      #|Object({"a": Object({"c": Number(1)})})
    ),
  )
}

///|
// Temporarily disabled
// test "missing: recurse with condition" {
//   inspect(test_feature("recurse(.+1; . < 5)", "1"), content="")
// }

///|
test "missing: walk function" {
  inspect(
    test_feature(
      "walk(if type == \"number\" then . * 2 else . end)", "{\"a\":1,\"b\":[2,3]}",
    ),
    content=(
      #|Object({"a": Number(2), "b": Array([Number(4), Number(6)])})
    ),
  )
}

///|
test "missing: pow function" {
  inspect(
    test_feature("pow(2; 3)", "null"),
    content=(
      #|ParseError: UnexpectedToken("TSemicolon", "TRParen")
    ),
  )
}

///|
test "missing: log function" {
  inspect(test_feature("log", "10"), content="Number(2.302585092994046)")
}

///|
test "missing: exp function" {
  inspect(test_feature("exp", "1"), content="Number(2.718281828459045)")
}

///|
test "missing: update operator |=" {
  inspect(test_feature(".a |= . + 1", "{\"a\":5}"), content="Number(6)")
}

///|
test "missing: assignment operator =" {
  inspect(test_feature(".a = 10", "{\"a\":5}"), content="Number(10)")
}

///|
test "missing: alternative operator //" {
  inspect(
    test_feature(".missing // \"default\"", "{}"),
    content=(
      #|String("default")
    ),
  )
}

///|
test "missing: += operator" {
  inspect(test_feature(".a += 5", "{\"a\":10}"), content="Number(15)")
}

///|
test "missing: -= operator" {
  inspect(test_feature(".a -= 3", "{\"a\":10}"), content="Number(7)")
}

///|
test "missing: *= operator" {
  inspect(test_feature(".a *= 2", "{\"a\":10}"), content="Number(20)")
}

///|
test "missing: /= operator" {
  inspect(test_feature(".a /= 2", "{\"a\":10}"), content="Number(5)")
}

///|
test "missing: %= operator" {
  inspect(test_feature(".a %= 3", "{\"a\":10}"), content="Number(1)")
}

///|
test "missing: //= operator" {
  inspect(test_feature(".a //= 99", "{}"), content="Number(99)")
}

///|
test "missing: string interpolation" {
  inspect(
    test_feature("\"Hello \\(.name)\"", "{\"name\":\"World\"}"),
    content="ParseError: InvalidEscape(8, '(')",
  )
}

///|
test "missing: @base64 format" {
  inspect(
    test_feature("@base64", "\"hello\""),
    content=(
      #|String("aGVsbG8=")
    ),
  )
}

///|
test "missing: @base64d format" {
  inspect(
    test_feature("@base64d", "\"aGVsbG8=\""),
    content=(
      #|String("hello")
    ),
  )
}

///|
test "missing: @uri format" {
  inspect(
    test_feature("@uri", "\"hello world\""),
    content=(
      #|String("hello+world")
    ),
  )
}

///|
test "missing: @csv format" {
  inspect(
    test_feature("@csv", "[[1,2,3]]"),
    content=(
      #|String("Array([Number(1), Number(2), Number(3)])")
    ),
  )
}

///|
test "missing: @json format" {
  inspect(
    test_feature("@json", "{\"a\":1}"),
    content=(
      #|String("Object({\"a\": Number(1)})")
    ),
  )
}

///|
test "missing: @html format" {
  inspect(
    test_feature("@html", "\"<div>\""),
    content=(
      #|String("&lt;div&gt;")
    ),
  )
}

///|
test "missing: @text format" {
  inspect(
    test_feature("@text", "\"hello\""),
    content=(
      #|String("String(\"hello\")")
    ),
  )
}

///|
test "missing: test(regex)" {
  inspect(
    test_feature(".text | test(\"^hello\")", "{\"text\":\"hello world\"}"),
    content="False",
  )
}

///|
test "missing: match(regex)" {
  inspect(
    test_feature(".text | match(\"[0-9]+\")", "{\"text\":\"abc123def\"}"),
    content="",
  )
}

///|
test "missing: capture(regex)" {
  inspect(
    test_feature(
      ".text | capture(\"(?<num>[0-9]+)\")", "{\"text\":\"abc123def\"}",
    ),
    content="Object({})",
  )
}

///|
test "missing: splits(regex)" {
  inspect(
    test_feature(".text | splits(\" +\")", "{\"text\":\"hello   world\"}"),
    content=(
      #|String("hello   world")
    ),
  )
}

///|
test "missing: sub(regex; replacement)" {
  inspect(
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
  inspect(
    test_feature(".text | gsub(\"o\"; \"0\")", "{\"text\":\"hello world\"}"),
    content=(
      #|String("hell0 w0rld")
    ),
  )
}

///|
test "missing: sin, cos, tan" {
  inspect(test_feature("sin", "0"), content="Number(0)")
  inspect(test_feature("cos", "0"), content="Number(1)")
  inspect(test_feature("tan", "0"), content="Number(0)")
}

///|
test "missing: asin, acos, atan" {
  inspect(test_feature("asin", "0"), content="Number(0)")
  inspect(test_feature("acos", "1"), content="Number(0)")
  inspect(test_feature("atan", "0"), content="Number(0)")
}

///|
test "missing: user-defined functions" {
  inspect(
    test_feature("def double: . * 2; double", "5"),
    content=(
      #|ParseError: UnexpectedToken("TDef", "expression")
    ),
  )
}

///|
test "missing: user-defined functions with params" {
  inspect(
    test_feature("def add(x): . + x; add(10)", "5"),
    content=(
      #|ParseError: UnexpectedToken("TDef", "expression")
    ),
  )
}

///|
test "missing: recursive user-defined functions" {
  inspect(
    test_feature(
      "def factorial: if . <= 1 then 1 else . * ((. - 1) | factorial) end; factorial",
      "5",
    ),
    content=(
      #|ParseError: UnexpectedToken("TDef", "expression")
    ),
  )
}

///|
test "missing: comments in query" {
  inspect(
    test_feature(". # this is a comment\n| .foo", "{\"foo\":42}"),
    content="Number(42)",
  )
}

///|
test "missing: multiline queries" {
  inspect(
    test_feature(".\n| .foo\n| . + 1", "{\"foo\":41}"),
    content="Number(42)",
  )
}
