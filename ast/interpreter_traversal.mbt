///|
/// Flatten array to specified depth
fn flatten_array_into(
  arr : Array[Json],
  depth : Int,
  out : Array[Json],
) -> Unit {
  if depth <= 0 {
    for elem in arr {
      out.push(elem)
    }
    return
  }
  for elem in arr {
    match elem {
      Array(inner) => flatten_array_into(inner, depth - 1, out)
      _ => out.push(elem)
    }
  }
}

///|
fn flatten_array(arr : Array[Json], depth : Int) -> Array[Json] {
  if depth <= 0 {
    return arr
  }
  let result : Array[Json] = []
  flatten_array_into(arr, depth, result)
  result
}

///|
/// Recursive descent: yield input and all nested values
fn recurse_all(input : Json) -> Iter[Json] {
  match input {
    Array(arr) =>
      Iter::singleton(input).concat(arr.iter().flat_map(recurse_all))
    Object(obj) =>
      Iter::singleton(input).concat(obj.values().flat_map(recurse_all))
    _ => Iter::singleton(input)
  }
}

///|
/// Evaluate RecurseWith
fn eval_recurse_with(
  f : Expr,
  _cond : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  let results : Array[Json] = [input]
  let to_process_ref : Ref[Array[Json]] = Ref::new([input])
  while not(to_process_ref.val.is_empty()) {
    let next_batch : Array[Json] = []
    for item in to_process_ref.val {
      for result in eval_with_env(f, item, env) {
        if result != item {
          results.push(result)
          next_batch.push(result)
        }
      }
    }
    to_process_ref.val = next_batch
    if to_process_ref.val.length() > 100 {
      break
    }
  }
  results.iter()
}

///|
/// Evaluate Walk
fn eval_walk(
  f : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  fn walk_value(v : Json) -> Json raise InterpreterError {
    match v {
      Array(arr) => {
        let walked = arr.map(walk_value)
        let wrapped = Json::array(walked)
        match eval_with_env(f, wrapped, env).collect() {
          [first, ..] => first
          [] => wrapped
        }
      }
      Object(obj) => {
        let walked : Map[String, Json] = {}
        for k, v in obj {
          walked[k] = walk_value(v)
        }
        let wrapped = Json::object(walked)
        match eval_with_env(f, wrapped, env).collect() {
          [first, ..] => first
          [] => wrapped
        }
      }
      _ =>
        match eval_with_env(f, v, env).collect() {
          [first, ..] => first
          [] => v
        }
    }
  }

  Iter::singleton(walk_value(input))
}
