///|
/// Evaluate field access against input JSON
fn eval_key_access(key : String, input : Json) -> Iterator[Json] {
  match input {
    Object(obj) =>
      match obj.get(key) {
        Some(v) => Iterator::singleton(v)
        None => Iterator::singleton(null)
      }
    _ => Iterator::singleton(null)
  }
}

///|
/// Evaluate array indexing and iteration
fn eval_index_access(indices : Array[Int], input : Json) -> Iterator[Json] {
  if indices.is_empty() {
    // Empty index means iterate over array/object values
    match input {
      Array(arr) => arr.iterator()
      Object(obj) => {
        let values : Array[Json] = []
        for _k, v in obj {
          values.push(v)
        }
        values.iterator()
      }
      _ => Iterator::empty()
    }
  } else {
    // Multiple indices produce multiple results
    indices
    .iterator()
    .map(fn(idx) {
      match input {
        Array(arr) => {
          let i = if idx < 0 { arr.length() + idx } else { idx }
          if i >= 0 && i < arr.length() {
            arr[i]
          } else {
            null
          }
        }
        _ => null
      }
    })
  }
}

///|
/// Evaluate array slicing
fn eval_slice_access(
  start : Int?,
  end : Int?,
  input : Json,
) -> Iterator[Json] {
  match input {
    Array(arr) => {
      let len = arr.length()
      let s = match start {
        Some(n) => if n < 0 { len + n } else { n }
        None => 0
      }
      let e = match end {
        Some(n) => if n < 0 { len + n } else { n }
        None => len
      }
      let result : Array[Json] = []
      for i = s; i < e && i < len; i = i + 1 {
        if i >= 0 {
          result.push(arr[i])
        }
      }
      Iterator::singleton(Json::array(result))
    }
    _ => Iterator::singleton(null)
  }
}

///|
/// Evaluate optional expression, suppressing errors
fn eval_optional(
  inner : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] {
  eval_with_env(inner, input, env) catch {
    _ => Iterator::empty()
  }
}
