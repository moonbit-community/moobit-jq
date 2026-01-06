///|
/// Evaluate Reduce
fn eval_reduce(
  expr : Expr,
  var_name : String,
  init_expr : Expr,
  update_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let init_results = eval_with_env(init_expr, input, env).collect()
  match init_results {
    [] => Iterator::singleton(null)
    [first, ..] => {
      let accumulator = eval_with_env(expr, input, env).fold(init=first, fn(
        acc,
        item,
      ) raise InterpreterError {
        let new_env = env.set(var_name, item)
        let update_results = eval_with_env(update_expr, acc, new_env).collect()
        match update_results {
          [] => acc
          [next, ..] => next
        }
      })
      Iterator::singleton(accumulator)
    }
  }
}

///|
/// Evaluate SortBy
fn eval_sort_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let pairs = arr.map(fn(elem) {
        let keys = eval_with_env(expr, elem, env).collect()
        let sort_key = match keys {
          [] => null
          [first, ..] => first
        }
        (elem, sort_key)
      })
      let sorted_pairs = pairs.copy()
      sorted_pairs.sort_by(fn(a, b) { compare_json(a.1, b.1) })
      let sorted = sorted_pairs.map(fn(p) { p.0 })
      Iterator::singleton(Json::array(sorted))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate GroupBy
fn eval_group_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let groups : Map[String, Array[Json]] = {}
      for elem in arr {
        let keys = eval_with_env(expr, elem, env).collect()
        let key_json = match keys {
          [] => null
          [first, ..] => first
        }
        let key_str = key_json.to_string()
        groups.update(key_str, fn(existing) {
          match existing {
            Some(group) => {
              group.push(elem)
              Some(group)
            }
            None => Some([elem])
          }
        })
      }
      let result : Array[Json] = []
      for group in groups.values() {
        result.push(Json::array(group))
      }
      Iterator::singleton(Json::array(result))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate Any
fn eval_any(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      Iterator::singleton(Json::boolean(arr.any(@ast_internal.is_truthy)))
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate All
fn eval_all(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      Iterator::singleton(Json::boolean(arr.all(@ast_internal.is_truthy)))
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}
