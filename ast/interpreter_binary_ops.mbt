///|
/// Evaluate binary operation
fn eval_binary_op(
  op : BinaryOp,
  left : Json,
  right : Json,
) -> Json raise InterpreterError {
  match op {
    Add => json_add(left, right)
    Subtract => json_subtract(left, right)
    Multiply => json_multiply(left, right)
    Divide => json_divide(left, right)
    Modulo => json_modulo(left, right)
    Equal => Json::boolean(compare_json(left, right) == 0)
    NotEqual => Json::boolean(compare_json(left, right) != 0)
    LessThan => Json::boolean(compare_json(left, right) < 0)
    LessEq => Json::boolean(compare_json(left, right) <= 0)
    GreaterThan => Json::boolean(compare_json(left, right) > 0)
    GreaterEq => Json::boolean(compare_json(left, right) >= 0)
    And =>
      if @ast_internal.is_truthy(left) {
        right
      } else {
        Json::boolean(false)
      }
    Or => if @ast_internal.is_truthy(left) { left } else { right }
  }
}

///|
/// Arithmetic operations
fn json_add(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => Json::number(a + b)
    (String(a), String(b)) => Json::string(a + b)
    (Array(a), Array(b)) => Json::array(a + b)
    (Object(a), Object(b)) => Json::object(a.merge(b))
    _ =>
      raise InvalidOperation(
        "Cannot add \{@ast_internal.json_type_name(left)} and \{@ast_internal.json_type_name(right)}",
      )
  }
}

///|
fn json_subtract(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => Json::number(a - b)
    (Array(a), Array(b)) => Json::array(array_without(a[:], b[:]))
    _ =>
      raise InvalidOperation(
        "Cannot subtract \{@ast_internal.json_type_name(right)} from \{@ast_internal.json_type_name(left)}",
      )
  }
}

///|
fn json_multiply(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => Json::number(a * b)
    (String(s), Number(n, ..)) | (Number(n, ..), String(s)) => {
      let count = n.to_int()
      Json::string(repeat_string(s, count))
    }
    _ =>
      raise InvalidOperation(
        "Cannot multiply \{@ast_internal.json_type_name(left)} and \{@ast_internal.json_type_name(right)}",
      )
  }
}

///|
fn repeat_string(s : String, count : Int) -> String {
  if count <= 0 {
    ""
  } else {
    s + repeat_string(s, count - 1)
  }
}

///|
fn array_contains_compare(haystack : ArrayView[Json], needle : Json) -> Bool {
  match haystack {
    [] => false
    [head, .. tail] =>
      if compare_json(head, needle) == 0 {
        true
      } else {
        array_contains_compare(tail, needle)
      }
  }
}

///|
fn array_without(
  source : ArrayView[Json],
  remove : ArrayView[Json],
) -> Array[Json] {
  match source {
    [] => []
    [head, .. tail] =>
      if array_contains_compare(remove, head) {
        array_without(tail, remove)
      } else {
        [head] + array_without(tail, remove)
      }
  }
}

///|
fn json_divide(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => {
      if b == 0.0 {
        raise DivisionByZero
      }
      Json::number(a / b)
    }
    _ =>
      raise InvalidOperation(
        "Cannot divide \{@ast_internal.json_type_name(left)} by \{@ast_internal.json_type_name(right)}",
      )
  }
}

///|
fn json_modulo(left : Json, right : Json) -> Json raise InterpreterError {
  match (left, right) {
    (Number(a, ..), Number(b, ..)) => {
      if b == 0.0 {
        raise DivisionByZero
      }
      Json::number(a % b)
    }
    _ =>
      raise InvalidOperation(
        "Cannot modulo \{@ast_internal.json_type_name(left)} by \{@ast_internal.json_type_name(right)}",
      )
  }
}
