///|
fn normalize_index(idx : Int, len : Int) -> Int {
  if idx < 0 { len + idx } else { idx }
}

///|
fn clamp_index(value : Int, len : Int) -> Int {
  if value < 0 {
    0
  } else if value > len {
    len
  } else {
    value
  }
}

///|
fn index_in_bounds(idx : Int, len : Int) -> Bool {
  idx >= 0 && idx < len
}

///|
fn array_index_or_null(arr : Array[Json], len : Int, idx : Int) -> Json {
  let actual_idx = normalize_index(idx, len)
  if index_in_bounds(actual_idx, len) {
    arr[actual_idx]
  } else {
    null
  }
}

///|
/// Evaluate field access against input JSON
fn eval_key_access(key : String, input : Json) -> Iter[Json] {
  match input {
    Object(obj) =>
      match obj.get(key) {
        Some(v) => Iter::singleton(v)
        None => Iter::singleton(null)
      }
    _ => Iter::singleton(null)
  }
}

///|
/// Evaluate array indexing and iteration
fn eval_index_access(indices : Array[Int], input : Json) -> Iter[Json] {
  if indices.is_empty() {
    // Empty index means iterate over array/object values
    match input {
      Array(arr) => arr.iter()
      Object(obj) => obj.values()
      _ => Iter::empty()
    }
  } else {
    // Multiple indices produce multiple results
    match input {
      Array(arr) => {
        let len = arr.length()
        indices.iter().map(fn(idx) { array_index_or_null(arr, len, idx) })
      }
      _ => indices.iter().map(fn(_) { null })
    }
  }
}

///|
/// Evaluate array slicing
fn eval_slice_access(start : Int?, end : Int?, input : Json) -> Iter[Json] {
  match input {
    Array(arr) => {
      let len = arr.length()
      let s = match start {
        Some(n) => normalize_index(n, len)
        None => 0
      }
      let e = match end {
        Some(n) => normalize_index(n, len)
        None => len
      }
      let s_clamped = clamp_index(s, len)
      let e_clamped = clamp_index(e, len)
      let sliced = if s_clamped >= e_clamped {
        []
      } else {
        arr[s_clamped:e_clamped].to_array()
      }
      Iter::singleton(Json::array(sliced))
    }
    _ => Iter::singleton(null)
  }
}

///|
/// Evaluate optional expression, suppressing errors
fn eval_optional(inner : Expr, input : Json, env : Env) -> Iter[Json] {
  eval_with_env(inner, input, env) catch {
    _ => Iter::empty()
  }
}
