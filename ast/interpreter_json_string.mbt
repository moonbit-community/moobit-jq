///|
/// Evaluate ToJsonString
fn eval_to_json_string(input : Json) -> Iterator[Json] {
  Iterator::singleton(Json::string(input.to_string()))
}

///|
/// Evaluate FromJsonString
fn eval_from_json_string(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => {
      let parsed = @json.parse(s) catch {
        e => raise InvalidOperation("JSON parse error: \{e}")
      }
      Iterator::singleton(parsed)
    }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}
