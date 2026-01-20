///|
/// Evaluate array sum
fn eval_add(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) => Iter::singleton(Json::number(sum_numbers(arr[:])))
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate floor
fn eval_floor(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iter::singleton(Json::number(n.floor()))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate square root
fn eval_sqrt(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iter::singleton(Json::number(n.sqrt()))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate minimum over array
fn eval_min(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match min_in_view(arr[:]) {
        Some(val) => Iter::singleton(val)
        None => Iter::singleton(null)
      }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate maximum over array
fn eval_max(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match max_in_view(arr[:]) {
        Some(val) => Iter::singleton(val)
        None => Iter::singleton(null)
      }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
fn sum_numbers(arr : ArrayView[Json]) -> Double {
  let mut total = 0.0
  for value in arr {
    match value {
      Number(n, ..) => total = total + n
      _ => ()
    }
  }
  total
}

///|
fn min_in_view(arr : ArrayView[Json]) -> Json? {
  let mut min_val : Json? = None
  for value in arr {
    match min_val {
      None => min_val = Some(value)
      Some(current) =>
        if compare_json(value, current) < 0 {
          min_val = Some(value)
        }
    }
  }
  min_val
}

///|
fn max_in_view(arr : ArrayView[Json]) -> Json? {
  let mut max_val : Json? = None
  for value in arr {
    match max_val {
      None => max_val = Some(value)
      Some(current) =>
        if compare_json(value, current) > 0 {
          max_val = Some(value)
        }
    }
  }
  max_val
}
