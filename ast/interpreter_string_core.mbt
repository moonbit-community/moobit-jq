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
  parts.map(fn(part) { Json::string(part.to_string()) })
}

///|
fn json_to_strings(parts : ArrayView[Json]) -> Array[String] {
  parts.map(fn(part) {
    match part {
      String(s) => s
      _ => part.to_string()
    }
  })
}

///|
fn array_contains_view(haystack : ArrayView[Json], needle : Json) -> Bool {
  haystack.contains(needle)
}

///|
fn array_contains_all(
  haystack : ArrayView[Json],
  needles : ArrayView[Json],
) -> Bool {
  needles.iter().all(needle => array_contains_view(haystack, needle))
}

///|
fn json_contains(container : Json, item : Json) -> Bool {
  match (container, item) {
    (String(haystack), String(n)) => haystack.contains(n)
    (Array(haystack), _) => array_contains_view(haystack[:], item)
    (Object(haystack), String(key)) => haystack.contains(key)
    _ => false
  }
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
    [needle, ..] => Iter::singleton(Json::boolean(json_contains(input, needle)))
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
        (Array(needle_arr), Array(haystack)) =>
          Iter::singleton(
            Json::boolean(array_contains_all(haystack[:], needle_arr[:])),
          )
        _ => Iter::singleton(Json::boolean(json_contains(container, input)))
      }
  }
}
