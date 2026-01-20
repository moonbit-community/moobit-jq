///|
/// Evaluate Combinations
fn eval_combinations(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match collect_arrays(arr[:]) {
        None => Iter::empty()
        Some(arrays) =>
          match arrays[:] {
            [] => Iter::empty()
            _ => cartesian_product(arrays[:]).iter().map(Json::array)
          }
      }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate Transpose
fn eval_transpose(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let max_len = max_row_len(arr[:])
      let rows = build_columns(arr[:], max_len)
      Iter::singleton(Json::array(rows.map(Json::array)))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
fn collect_arrays(items : ArrayView[Json]) -> Array[Array[Json]]? {
  let arrays : Array[Array[Json]] = []
  for item in items {
    match item {
      Array(inner) => arrays.push(inner)
      _ => return None
    }
  }
  Some(arrays)
}

///|
fn cartesian_product(arrays : ArrayView[Array[Json]]) -> Array[Array[Json]] {
  let mut result : Array[Array[Json]] = [[]]
  for arr in arrays {
    let next : Array[Array[Json]] = []
    for prefix in result {
      for item in arr {
        let combined = prefix.copy()
        combined.push(item)
        next.push(combined)
      }
    }
    result = next
  }
  result
}

///|
fn max_row_len(rows : ArrayView[Json]) -> Int {
  let mut max_len = 0
  for row in rows {
    match row {
      Array(inner) =>
        if inner.length() > max_len {
          max_len = inner.length()
        }
      _ => ()
    }
  }
  max_len
}

///|
fn build_columns(
  rows : ArrayView[Json],
  max_len : Int,
) -> Array[Array[Json]] {
  let columns : Array[Array[Json]] = []
  for col in 0..<max_len {
    let column : Array[Json] = []
    for row in rows {
      match row {
        Array(inner) =>
          if col < inner.length() {
            column.push(inner[col])
          }
        _ => ()
      }
    }
    columns.push(column)
  }
  columns
}
