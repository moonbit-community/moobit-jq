///|
/// Evaluate length
fn eval_length(input : Json) -> Iterator[Json] raise InterpreterError {
  let len = match input {
    Array(arr) => arr.length()
    Object(obj) => obj.length()
    String(s) => s.length()
    Null => 0
    _ =>
      raise TypeMismatch(
        "array/object/string",
        @ast_internal.json_type_name(input),
      )
  }
  Iterator::singleton(Json::number(len.to_double()))
}

///|
/// Evaluate keys
fn eval_keys(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Object(obj) =>
      Iterator::singleton(
        Json::array(
          obj
          .to_array()
          .map(fn(pair) {
            let (k, _v) = pair
            Json::string(k)
          }),
        ),
      )
    Array(arr) => {
      let indices = arr.mapi((i, _) => Json::number(i.to_double()))
      Iterator::singleton(Json::array(indices))
    }
    _ => raise TypeMismatch("object/array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate values
fn eval_values(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Object(obj) =>
      Iterator::singleton(
        Json::array(
          obj
          .to_array()
          .map(fn(pair) {
            let (_k, v) = pair
            v
          }),
        ),
      )
    Array(arr) => Iterator::singleton(Json::array(arr))
    _ => raise TypeMismatch("object/array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate type
fn eval_type(input : Json) -> Iterator[Json] {
  Iterator::singleton(Json::string(@ast_internal.json_type_name(input)))
}

///|
/// Evaluate empty
fn eval_empty() -> Iterator[Json] {
  Iterator::empty()
}

///|
/// Evaluate logical not
fn eval_not(input : Json) -> Iterator[Json] {
  Iterator::singleton(Json::boolean(not(@ast_internal.is_truthy(input))))
}
