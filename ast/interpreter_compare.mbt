///|
/// Compare JSON values for sorting
fn compare_json(a : Json, b : Json) -> Int {
  match (a, b) {
    (Null, Null) => 0
    (Null, _) => -1
    (_, Null) => 1
    (False, False) => 0
    (False, True) => -1
    (True, False) => 1
    (True, True) => 0
    (Number(x, ..), Number(y, ..)) => x.compare(y)
    (String(x), String(y)) => x.compare(y)
    (Array(x), Array(y)) => compare_array_view(x[:], y[:])
    // Type ordering: null < bool < number < string < array < object
    (False | True, Number(_)) => -1
    (Number(_), False | True) => 1
    (Number(_), String(_)) => -1
    (String(_), Number(_)) => 1
    (String(_), Array(_)) => -1
    (Array(_), String(_)) => 1
    (Array(_), Object(_)) => -1
    (Object(_), Array(_)) => 1
    (Object(_), Object(_)) => 0 // Objects compare equal
    _ => 0
  }
}

///|
fn compare_array_view(a : ArrayView[Json], b : ArrayView[Json]) -> Int {
  match (a, b) {
    ([], []) => 0
    ([], _) => -1
    (_, []) => 1
    ([head_a, .. tail_a], [head_b, .. tail_b]) => {
      let cmp = compare_json(head_a, head_b)
      if cmp != 0 {
        cmp
      } else {
        compare_array_view(tail_a, tail_b)
      }
    }
  }
}
