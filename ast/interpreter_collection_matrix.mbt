///|
/// Evaluate Combinations
fn eval_combinations(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      match collect_arrays(arr[:]) {
        None => Iterator::empty()
        Some(arrays) =>
          match arrays[:] {
            [] => Iterator::empty()
            _ => cartesian_product(arrays[:]).iterator().map(Json::array)
          }
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate Transpose
fn eval_transpose(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let max_len = max_row_len(arr[:])
      let rows = build_columns(arr[:], 0, max_len)
      Iterator::singleton(Json::array(rows.map(Json::array)))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
fn collect_arrays(items : ArrayView[Json]) -> Array[Array[Json]]? {
  match items {
    [] => Some([])
    [Array(inner), ..tail] =>
      match collect_arrays(tail) {
        Some(rest) => Some([inner] + rest)
        None => None
      }
    [_other, .. _] => None
  }
}

///|
fn cartesian_product(arrays : ArrayView[Array[Json]]) -> Array[Array[Json]] {
  match arrays {
    [] => [[]]
    [head, ..tail] => {
      let tail_results = cartesian_product(tail)
      combine_with_all(head[:], tail_results[:])
    }
  }
}

///|
fn combine_with_all(
  items : ArrayView[Json],
  tails : ArrayView[Array[Json]],
) -> Array[Array[Json]] {
  match items {
    [] => []
    [head, ..rest] =>
      prepend_to_all(head, tails) + combine_with_all(rest, tails)
  }
}

///|
fn prepend_to_all(
  item : Json,
  tails : ArrayView[Array[Json]],
) -> Array[Array[Json]] {
  match tails {
    [] => []
    [tail, ..rest] => [[item] + tail] + prepend_to_all(item, rest)
  }
}

///|
fn max_row_len(rows : ArrayView[Json]) -> Int {
  match rows {
    [] => 0
    [Array(inner), ..tail] => {
      let tail_max = max_row_len(tail)
      if inner.length() > tail_max {
        inner.length()
      } else {
        tail_max
      }
    }
    [_other, ..tail] => max_row_len(tail)
  }
}

///|
fn build_columns(rows : ArrayView[Json], col : Int, max_len : Int) -> Array[Array[Json]] {
  if col >= max_len {
    []
  } else {
    [column_values(rows, col)] + build_columns(rows, col + 1, max_len)
  }
}

///|
fn column_values(rows : ArrayView[Json], col : Int) -> Array[Json] {
  match rows {
    [] => []
    [Array(inner), ..tail] =>
      if col < inner.length() {
        [inner[col]] + column_values(tail, col)
      } else {
        column_values(tail, col)
      }
    [_other, ..tail] => column_values(tail, col)
  }
}
