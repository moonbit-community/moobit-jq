///|
/// Evaluate length
fn eval_length(input : Json) -> Iterator[Json] raise InterpreterError {
  let len = match input {
    Array(arr) => arr.length()
    Object(obj) => obj.length()
    String(s) => s.length()
    Null => 0
    _ => raise TypeMismatch("array/object/string", json_type_name(input))
  }
  Iterator::singleton(Json::number(len.to_double()))
}

///|
/// Evaluate keys
fn eval_keys(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Object(obj) => {
      let keys : Array[Json] = []
      for k, _v in obj {
        keys.push(Json::string(k))
      }
      Iterator::singleton(Json::array(keys))
    }
    Array(arr) => {
      let indices = arr.mapi((i, _) => Json::number(i.to_double()))
      Iterator::singleton(Json::array(indices))
    }
    _ => raise TypeMismatch("object/array", json_type_name(input))
  }
}

///|
/// Evaluate values
fn eval_values(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Object(obj) => {
      let values : Array[Json] = []
      for _k, v in obj {
        values.push(v)
      }
      Iterator::singleton(Json::array(values))
    }
    Array(arr) => Iterator::singleton(Json::array(arr))
    _ => raise TypeMismatch("object/array", json_type_name(input))
  }
}

///|
/// Evaluate type
fn eval_type(input : Json) -> Iterator[Json] {
  Iterator::singleton(Json::string(json_type_name(input)))
}

///|
/// Evaluate empty
fn eval_empty() -> Iterator[Json] {
  Iterator::empty()
}

///|
/// Evaluate logical not
fn eval_not(input : Json) -> Iterator[Json] {
  Iterator::singleton(Json::boolean(not(is_truthy(input))))
}
