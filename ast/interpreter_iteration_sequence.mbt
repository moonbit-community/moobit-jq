///|
/// Evaluate range
fn eval_range(n : Int) -> Iterator[Json] {
  let results : Array[Json] = []
  for i = 0; i < n; i = i + 1 {
    results.push(Json::number(i.to_double()))
  }
  results.iterator()
}

///|
/// Evaluate first element
fn eval_first(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if arr.is_empty() {
        Iterator::empty()
      } else {
        Iterator::singleton(arr[0])
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate last element
fn eval_last(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if arr.is_empty() {
        Iterator::empty()
      } else {
        Iterator::singleton(arr[arr.length() - 1])
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}
