///|
/// Evaluate regex test (simple contains)
fn eval_test(
  pattern : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => Iterator::singleton(Json::boolean(s.contains(pattern)))
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate regex match (simple contains)
fn eval_match(
  pattern : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) =>
      if s.contains(pattern) {
        Iterator::singleton(
          Json::object(
            Map::from_array([
              ("match", Json::string(pattern)),
              ("offset", Json::number(0.0)),
              ("length", Json::number(pattern.length().to_double())),
              ("string", Json::string(s)),
              ("captures", Json::array([])),
            ]),
          ),
        )
      } else {
        Iterator::empty()
      }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate regex capture (placeholder)
fn eval_capture(
  _pattern : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(_s) => Iterator::singleton(Json::object(Map::from_array([])))
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate regex splits (simple split)
fn eval_splits(
  pattern : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => {
      let parts = s.split(pattern).collect()
      parts.iterator().map(part => Json::string(part.to_string()))
    }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate regex sub (simple replace)
fn eval_sub(
  pattern : String,
  replacement : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) =>
      Iterator::singleton(
        Json::string(s.replace(old=pattern[:], new=replacement[:])),
      )
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate regex gsub (simple replace all)
fn eval_gsub(
  pattern : String,
  replacement : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) =>
      Iterator::singleton(
        Json::string(s.replace_all(old=pattern[:], new=replacement[:])),
      )
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}
