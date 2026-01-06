///|
/// Evaluate has for object keys or array indices
fn eval_has(key : String, input : Json) -> Iterator[Json] {
  match input {
    Object(obj) => Iterator::singleton(Json::boolean(obj.contains(key)))
    Array(arr) => {
      let idx_result = @strconv.parse_int(key) catch {
        _ => return Iterator::singleton(Json::boolean(false))
      }
      let len = arr.length()
      let actual_idx = if idx_result < 0 {
        len + idx_result
      } else {
        idx_result
      }
      Iterator::singleton(Json::boolean(actual_idx >= 0 && actual_idx < len))
    }
    _ => Iterator::singleton(Json::boolean(false))
  }
}

///|
/// Evaluate membership with container expression
fn eval_in(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match eval_with_env(expr, input, env).collect() {
    [] => Iterator::singleton(Json::boolean(false))
    [Object(obj), ..] =>
      match input {
        String(key) => Iterator::singleton(Json::boolean(obj.contains(key)))
        _ => Iterator::singleton(Json::boolean(false))
      }
    [Array(arr), ..] =>
      match input {
        Number(n, ..) => {
          let idx = n.to_int()
          let len = arr.length()
          let actual_idx = if idx < 0 { len + idx } else { idx }
          Iterator::singleton(
            Json::boolean(actual_idx >= 0 && actual_idx < len),
          )
        }
        _ => Iterator::singleton(Json::boolean(false))
      }
    _ => Iterator::singleton(Json::boolean(false))
  }
}

///|
/// Evaluate to_entries
fn eval_to_entries(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Object(obj) =>
      Iterator::singleton(
        Json::array(
          obj
          .to_array()
          .map(fn(pair) {
            let (k, v) = pair
            entry_from_pair(Json::string(k), v)
          }),
        ),
      )
    Array(arr) =>
      Iterator::singleton(
        Json::array(
          arr.mapi(fn(i, v) { entry_from_pair(Json::number(i.to_double()), v) }),
        ),
      )
    _ => raise TypeMismatch("object/array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate from_entries
fn eval_from_entries(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      Iterator::singleton(
        Json::object(Map::from_array(arr.filter_map(entry_to_pair)[:])),
      )
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
fn entry_from_pair(key : Json, value : Json) -> Json {
  let entry : Map[String, Json] = { "key": key, "value": value }
  Json::object(entry)
}

///|
fn entry_to_pair(entry : Json) -> (String, Json)? {
  match entry {
    Object(obj) => {
      let key_opt = match obj.get("key") {
        Some(k) => Some(k)
        None => obj.get("name")
      }
      let value_opt = obj.get("value")
      match (key_opt, value_opt) {
        (Some(String(key_str)), Some(v)) => Some((key_str, v))
        (Some(Number(n, ..)), Some(v)) => Some((n.to_int().to_string(), v))
        _ => None
      }
    }
    _ => None
  }
}

///|
/// Evaluate with_entries
fn eval_with_entries(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Object(_) | Array(_) => {
      let entries_results = eval_with_env(ToEntries, input, env).collect()
      let entries_array = entries_results[0]
      let mapped_results = eval_with_env(Map(expr), entries_array, env).collect()
      eval_with_env(FromEntries, mapped_results[0], env)
    }
    _ => raise TypeMismatch("object/array", @ast_internal.json_type_name(input))
  }
}
