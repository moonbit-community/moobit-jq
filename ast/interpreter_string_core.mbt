///|
/// Evaluate string split
fn eval_split(
  sep : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => {
      let parts = s.split(sep).collect()
      let json_parts = string_views_to_json(parts[:])
      Iterator::singleton(Json::array(json_parts))
    }
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate string join
fn eval_join(
  sep : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let parts = json_to_strings(arr[:])
      Iterator::singleton(Json::string(parts.join(sep)))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate prefix check
fn eval_starts_with(
  prefix : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => Iterator::singleton(Json::boolean(s.has_prefix(prefix)))
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate suffix check
fn eval_ends_with(
  suffix : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => Iterator::singleton(Json::boolean(s.has_suffix(suffix)))
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
fn string_views_to_json(parts : ArrayView[StringView]) -> Array[Json] {
  match parts {
    [] => []
    [head, .. tail] =>
      [Json::string(head.to_string())] + string_views_to_json(tail)
  }
}

///|
fn json_to_strings(parts : ArrayView[Json]) -> Array[String] {
  match parts {
    [] => []
    [String(s), .. tail] => [s] + json_to_strings(tail)
    [head, .. tail] => [head.to_string()] + json_to_strings(tail)
  }
}

///|
fn array_contains_view(haystack : ArrayView[Json], needle : Json) -> Bool {
  match haystack {
    [] => false
    [head, .. tail] =>
      if head == needle {
        true
      } else {
        array_contains_view(tail, needle)
      }
  }
}

///|
fn array_contains_all(
  haystack : ArrayView[Json],
  needles : ArrayView[Json],
) -> Bool {
  match (needles, haystack) {
    ([], _) => true
    ([needle, .. rest], _) =>
      if array_contains_view(haystack, needle) {
        array_contains_all(haystack, rest)
      } else {
        false
      }
  }
}

///|
/// Evaluate contains for strings, arrays, and objects
fn eval_contains(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match eval_with_env(expr, input, env).collect() {
    [] => Iterator::singleton(Json::boolean(false))
    [needle, ..] =>
      match (input, needle) {
        (String(haystack), String(n)) =>
          Iterator::singleton(Json::boolean(haystack.contains(n)))
        (Array(haystack), _) =>
          Iterator::singleton(
            Json::boolean(array_contains_view(haystack[:], needle)),
          )
        (Object(haystack), String(key)) =>
          Iterator::singleton(Json::boolean(haystack.contains(key)))
        _ => Iterator::singleton(Json::boolean(false))
      }
  }
}

///|
/// Evaluate inside for strings, arrays, and objects
fn eval_inside(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match eval_with_env(expr, input, env).collect() {
    [] => Iterator::singleton(Json::boolean(false))
    [container, ..] =>
      match (input, container) {
        (String(needle), String(haystack)) =>
          Iterator::singleton(Json::boolean(haystack.contains(needle)))
        (Array(needle_arr), Array(haystack)) =>
          Iterator::singleton(
            Json::boolean(array_contains_all(haystack[:], needle_arr[:])),
          )
        (String(key), Object(haystack)) =>
          Iterator::singleton(Json::boolean(haystack.contains(key)))
        _ => Iterator::singleton(Json::boolean(false))
      }
  }
}
