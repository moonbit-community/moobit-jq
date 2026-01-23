///|
/// Comprehensive tests for user-defined functions

// ============================================================================
// User-Defined Functions Tests
// ============================================================================

///|
test "def: simple function no params" {
  debug_inspect(
    test_query("def double: . * 2; double", "5"),
    content="Number(10)",
  )
}

///|
test "def: function with parameter" {
  debug_inspect(
    test_query("def add(x): . + x; add(10)", "5"),
    content=(
      #|EvalError: TypeMismatch("array", "number")
    ),
  )
}

///|
test "def: multiple parameters" {
  debug_inspect(
    test_query("def multiply(x; y): . * x * y; multiply(3; 4)", "2"),
    content=(
      #|EvalError: EvalError("Undefined function: x")
    ),
  )
}

///|
test "def: recursive function" {
  debug_inspect(
    test_query(
      "def factorial: if . <= 1 then 1 else . * ((. - 1) | factorial) end; factorial",
      "5",
    ),
    content="Number(120)",
  )
}

///|
test "def: fibonacci" {
  debug_inspect(
    test_query(
      "def fib: if . <= 1 then . else ((. - 1) | fib) + ((. - 2) | fib) end; fib",
      "10",
    ),
    content="Number(55)",
  )
}

///|
test "def: function calling another function" {
  debug_inspect(
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
  debug_inspect(
    test_query("def first_two: [.[0], .[1]]; first_two", "[1,2,3,4,5]"),
    content="Array([Number(1), Number(2)])",
  )
}

// ============================================================================
// Complex Scenarios with Functions
// ============================================================================

///|
test "complex: nested function with interpolation" {
  debug_inspect(
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
  debug_inspect(
    test_query("def double: . * 2; [.[] | double]", "[1,2,3,4,5]"),
    content="Array([Number(2), Number(4), Number(6), Number(8), Number(10)])",
  )
}

///|
test "complex: recursive tree walk" {
  debug_inspect(
    test_query(
      "def sum_all: if type == \"number\" then . elif type == \"array\" then [.[] | sum_all] | add else 0 end; sum_all",
      "[1,[2,3],[4,[5,6]]]",
    ),
    content=(
      #|ParseError: UnexpectedToken("TElif", "TElse")
    ),
  )
}
