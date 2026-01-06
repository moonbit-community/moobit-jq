///|
/// Evaluate map over array elements
fn eval_map(
  inner : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
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
      Iterator::singleton(Json::array(results))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate select filter
fn eval_select(
  condition : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let cond_results = eval_with_env(condition, input, env).collect()
  match @ast_internal.first_opt(cond_results) {
    None => Iterator::empty()
    Some(first) =>
      if @ast_internal.is_truthy(first) {
        Iterator::singleton(input)
      } else {
        Iterator::empty()
      }
  }
}

///|
/// Evaluate array sort
fn eval_sort(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let sorted = arr.copy()
      sorted.sort_by(compare_json)
      Iterator::singleton(Json::array(sorted))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate array reverse
fn eval_reverse(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => Iterator::singleton(Json::array(arr.rev()))
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate array flatten
fn eval_flatten(
  depth_opt : Int?,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let depth = match depth_opt {
        Some(d) => d
        None => 999999 // Flatten all levels
      }
      Iterator::singleton(Json::array(flatten_array(arr, depth)))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate array unique
fn eval_unique(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let sorted = arr.copy()
      sorted.sort_by(compare_json)
      let (unique, _prev) : (Array[Json], Json?) = sorted.fold(
        init=([], None),
        fn(state, elem) {
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
        },
      )
      Iterator::singleton(Json::array(unique))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}
