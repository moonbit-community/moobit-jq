///|
/// Evaluate map over array elements
fn eval_map(
  inner : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  let results : Array[Json] = arr.fold(init=[], fn(
    acc,
    elem,
  ) raise InterpreterError {
    let mapped = eval_with_env(inner, elem, env).collect()
    for v in mapped {
      acc.push(v)
    }
    acc
  })
  Iter::singleton(Json::array(results))
}

///|
/// Evaluate select filter
fn eval_select(
  condition : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match eval_with_env(condition, input, env).collect() {
    [] => Iter::empty()
    [first, ..] =>
      if @ast_internal.is_truthy(first) {
        Iter::singleton(input)
      } else {
        Iter::empty()
      }
  }
}

///|
/// Evaluate array sort
fn eval_sort(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  let sorted = arr.copy()
  sorted.sort_by(compare_json)
  Iter::singleton(Json::array(sorted))
}

///|
/// Evaluate array reverse
fn eval_reverse(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  Iter::singleton(Json::array(arr.rev()))
}

///|
/// Evaluate array flatten
fn eval_flatten(
  depth_opt : Int?,
  input : Json,
) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  let depth = depth_opt.unwrap_or(999999) // Flatten all levels
  Iter::singleton(Json::array(flatten_array(arr, depth)))
}

///|
/// Evaluate array unique
fn eval_unique(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is Array(arr) else {
    raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
  let sorted = arr.copy()
  sorted.sort_by(compare_json)
  let (unique, _prev) : (Array[Json], Json?) = sorted.fold(init=([], None), fn(
    state,
    elem,
  ) {
    let (acc, prev) = state
    match prev {
      None => {
        acc.push(elem)
        (acc, Some(elem))
      }
      Some(p) =>
        if compare_json(p, elem) != 0 {
          acc.push(elem)
          (acc, Some(elem))
        } else {
          (acc, prev)
        }
    }
  })
  Iter::singleton(Json::array(unique))
}
