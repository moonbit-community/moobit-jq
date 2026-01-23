///|
/// Comprehensive tests for math and control flow

// ============================================================================
// Mathematical Operations
// ============================================================================

///|
test "pow: power function" {
  debug_inspect(test_query("pow(2; 10)", "null"), content="Number(1024)")
}

///|
test "log: natural logarithm" {
  debug_inspect(
    test_query("log", "2.718281828"),
    content="Number(0.9999999998311266)",
  )
}

///|
test "exp: exponential" {
  debug_inspect(test_query("exp", "1"), content="Number(2.718281828459045)")
}

///|
test "sin: sine" {
  debug_inspect(test_query("sin", "0"), content="Number(0)")
}

///|
test "cos: cosine" {
  debug_inspect(test_query("cos", "0"), content="Number(1)")
}

///|
test "sqrt: square root" {
  debug_inspect(test_query("sqrt", "16"), content="Number(4)")
}

///|
test "floor: floor function" {
  debug_inspect(test_query("floor", "3.7"), content="Number(3)")
}

///|
test "ceil: ceiling function" {
  debug_inspect(test_query("ceil", "3.2"), content="Number(4)")
}

// ============================================================================
// Control Flow Tests
// ============================================================================

///|
test "if-then-else: basic conditional" {
  debug_inspect(
    test_query("if . > 10 then \"big\" else \"small\" end", "15"),
    content="String(\"big\")",
  )
}

///|
test "if-then-elif-else: multiple conditions" {
  debug_inspect(
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
  debug_inspect(test_query("try .x catch \"error\"", "{}"), content="Null")
}

///|
test "alternative operator: fallback" {
  debug_inspect(test_query(".x // 42", "{\"y\":10}"), content="Number(42)")
}

///|
test "alternative operator: with value" {
  debug_inspect(test_query(".x // 42", "{\"x\":5}"), content="Number(5)")
}
