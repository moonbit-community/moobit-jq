///|
/// Evaluate string split
fn eval_split(sep : String, input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    String(s) => {
      let parts = s.split(sep).collect()
      let json_parts = string_views_to_json(parts[:])
      Iter::singleton(Json::array(json_parts))
    }
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate string join
fn eval_join(sep : String, input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let parts = json_to_strings(arr[:])
      Iter::singleton(Json::string(parts.join(sep)))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate prefix check
fn eval_starts_with(
  prefix : String,
  input : Json,
) -> Iter[Json] raise InterpreterError {
  match input {
    String(s) => Iter::singleton(Json::boolean(s.has_prefix(prefix)))
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate suffix check
fn eval_ends_with(
  suffix : String,
  input : Json,
) -> Iter[Json] raise InterpreterError {
  match input {
    String(s) => Iter::singleton(Json::boolean(s.has_suffix(suffix)))
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
fn string_views_to_json(parts : ArrayView[StringView]) -> Array[Json] {
  let results : Array[Json] = []
  for part in parts {
    results.push(Json::string(part.to_string()))
  }
  results
}

///|
fn json_to_strings(parts : ArrayView[Json]) -> Array[String] {
  let results : Array[String] = []
  for part in parts {
    match part {
      String(s) => results.push(s)
      _ => results.push(part.to_string())
    }
  }
  results
}

///|
fn array_contains_view(haystack : ArrayView[Json], needle : Json) -> Bool {
  haystack.iter().any(item => item == needle)
}

///|
fn array_contains_all(
  haystack : ArrayView[Json],
  needles : ArrayView[Json],
) -> Bool {
  needles.iter().all(needle => array_contains_view(haystack, needle))
}

///|
/// Evaluate contains for strings, arrays, and objects
fn eval_contains(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match eval_with_env(expr, input, env).collect() {
    [] => Iter::singleton(Json::boolean(false))
    [needle, ..] =>
      match (input, needle) {
        (String(haystack), String(n)) =>
          Iter::singleton(Json::boolean(haystack.contains(n)))
        (Array(haystack), _) =>
          Iter::singleton(
            Json::boolean(array_contains_view(haystack[:], needle)),
          )
        (Object(haystack), String(key)) =>
          Iter::singleton(Json::boolean(haystack.contains(key)))
        _ => Iter::singleton(Json::boolean(false))
      }
  }
}

///|
/// Evaluate inside for strings, arrays, and objects
fn eval_inside(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] raise InterpreterError {
  match eval_with_env(expr, input, env).collect() {
    [] => Iter::singleton(Json::boolean(false))
    [container, ..] =>
      match (input, container) {
        (String(needle), String(haystack)) =>
          Iter::singleton(Json::boolean(haystack.contains(needle)))
        (Array(needle_arr), Array(haystack)) =>
          Iter::singleton(
            Json::boolean(array_contains_all(haystack[:], needle_arr[:])),
          )
        (String(key), Object(haystack)) =>
          Iter::singleton(Json::boolean(haystack.contains(key)))
        _ => Iter::singleton(Json::boolean(false))
      }
  }
}
