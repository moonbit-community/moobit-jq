///|
/// Evaluate array sum
fn eval_add(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(sum_numbers(arr[:])))
}

///|
/// Evaluate floor
fn eval_floor(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(n.floor()))
}

///|
/// Evaluate square root
fn eval_sqrt(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Number(n, ..) else {
    raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::number(n.sqrt()))
}

///|
/// Evaluate minimum over array
fn eval_min(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  Iter::singleton(min_in_view(arr[:]).unwrap_or(null))
}

///|
/// Evaluate maximum over array
fn eval_max(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  Iter::singleton(max_in_view(arr[:]).unwrap_or(null))
}

///|
fn sum_numbers(arr : ArrayView[Json]) -> Double {
  arr.fold(init=0.0, fn(total, value) {
    match value {
      Number(n, ..) => total + n
      _ => total
    }
  })
}

///|
fn min_in_view(arr : ArrayView[Json]) -> Json? {
  arr.fold(init=None, fn(min_val : Json?, value) {
    match min_val {
      None => Some(value)
      Some(current) =>
        if compare_json(value, current) < 0 {
          Some(value)
        } else {
          min_val
        }
    }
  })
}

///|
fn max_in_view(arr : ArrayView[Json]) -> Json? {
  arr.fold(init=None, fn(max_val : Json?, value) {
    match max_val {
      None => Some(value)
      Some(current) =>
        if compare_json(value, current) > 0 {
          Some(value)
        } else {
          max_val
        }
    }
  })
}
