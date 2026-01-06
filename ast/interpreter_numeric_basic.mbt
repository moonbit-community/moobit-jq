///|
/// Evaluate array sum
fn eval_add(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => Iterator::singleton(Json::number(sum_numbers(arr[:])))
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate floor
fn eval_floor(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.floor()))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate square root
fn eval_sqrt(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.sqrt()))
    _ => raise TypeMismatch("number", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate minimum over array
fn eval_min(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match min_in_view(arr[:]) {
        Some(val) => Iterator::singleton(val)
        None => Iterator::singleton(null)
      }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate maximum over array
fn eval_max(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match max_in_view(arr[:]) {
        Some(val) => Iterator::singleton(val)
        None => Iterator::singleton(null)
      }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
fn sum_numbers(arr : ArrayView[Json]) -> Double {
  match arr {
    [] => 0.0
    [Number(n, ..), .. tail] => n + sum_numbers(tail)
    [_head, .. tail] => sum_numbers(tail)
  }
}

///|
fn min_in_view(arr : ArrayView[Json]) -> Json? {
  match arr {
    [] => None
    [head, .. tail] => Some(min_in_tail(head, tail))
  }
}

///|
fn min_in_tail(current : Json, rest : ArrayView[Json]) -> Json {
  match rest {
    [] => current
    [head, .. tail] => {
      let next = if compare_json(head, current) < 0 { head } else { current }
      min_in_tail(next, tail)
    }
  }
}

///|
fn max_in_view(arr : ArrayView[Json]) -> Json? {
  match arr {
    [] => None
    [head, .. tail] => Some(max_in_tail(head, tail))
  }
}

///|
fn max_in_tail(current : Json, rest : ArrayView[Json]) -> Json {
  match rest {
    [] => current
    [head, .. tail] => {
      let next = if compare_json(head, current) > 0 { head } else { current }
      max_in_tail(next, tail)
    }
  }
}
