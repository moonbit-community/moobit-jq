///|
/// Evaluate map over array elements
fn eval_map(
  inner : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let results : Array[Json] = []
      for elem in arr {
        let mapped = eval_with_env(inner, elem, env).collect()
        for v in mapped {
          results.push(v)
        }
      }
      Iterator::singleton(Json::array(results))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
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
  if cond_results.is_empty() {
    Iterator::empty()
  } else {
    let truthy = is_truthy(cond_results[0])
    if truthy {
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
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate array reverse
fn eval_reverse(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let reversed : Array[Json] = []
      for i = arr.length() - 1; i >= 0; i = i - 1 {
        reversed.push(arr[i])
      }
      Iterator::singleton(Json::array(reversed))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
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
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate array unique
fn eval_unique(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let sorted = arr.copy()
      sorted.sort_by(compare_json)
      let unique : Array[Json] = []
      let mut prev : Json? = None
      for elem in sorted {
        match prev {
          None => {
            unique.push(elem)
            prev = Some(elem)
          }
          Some(p) =>
            if compare_json(p, elem) != 0 {
              unique.push(elem)
              prev = Some(elem)
            }
        }
      }
      Iterator::singleton(Json::array(unique))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}
