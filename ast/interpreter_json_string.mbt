///|
/// Evaluate ToJsonString
fn eval_to_json_string(input : Json) -> Iter[Json] {
  Iter::singleton(Json::string(input.to_string()))
}

///|
/// Evaluate FromJsonString
fn eval_from_json_string(input : Json) -> Iter[Json] raise InterpreterError {
  guard input is String(s) else {
    raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
  let parsed = @json.parse(s) catch {
    e => raise InvalidOperation("JSON parse error: \{e}")
  }
  Iter::singleton(parsed)
}
