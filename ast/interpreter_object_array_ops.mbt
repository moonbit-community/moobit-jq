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
      let actual_idx = if idx_result < 0 { len + idx_result } else { idx_result }
      Iterator::singleton(
        Json::boolean(actual_idx >= 0 && actual_idx < len),
      )
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
  let container_results = eval_with_env(expr, input, env).collect()
  if container_results.is_empty() {
    return Iterator::singleton(Json::boolean(false))
  }
  match container_results[0] {
    Object(obj) =>
      match input {
        String(key) => Iterator::singleton(Json::boolean(obj.contains(key)))
        _ => Iterator::singleton(Json::boolean(false))
      }
    Array(arr) =>
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
    Object(obj) => {
      let entries : Array[Json] = []
      for k, v in obj {
        let entry : Map[String, Json] = {}
        entry["key"] = Json::string(k)
        entry["value"] = v
        entries.push(Json::object(entry))
      }
      Iterator::singleton(Json::array(entries))
    }
    Array(arr) => {
      let entries : Array[Json] = []
      for i = 0; i < arr.length(); i = i + 1 {
        let entry : Map[String, Json] = {}
        entry["key"] = Json::number(i.to_double())
        entry["value"] = arr[i]
        entries.push(Json::object(entry))
      }
      Iterator::singleton(Json::array(entries))
    }
    _ => raise TypeMismatch("object/array", json_type_name(input))
  }
}

///|
/// Evaluate from_entries
fn eval_from_entries(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let result : Map[String, Json] = {}
      for entry in arr {
        match entry {
          Object(obj) => {
            let key_opt = match obj.get("key") {
              Some(k) => Some(k)
              None => obj.get("name")
            }
            let value_opt = obj.get("value")
            match key_opt {
              Some(k) =>
                match k {
                  String(key_str) =>
                    match value_opt {
                      Some(v) => result[key_str] = v
                      None => ()
                    }
                  Number(n, ..) =>
                    match value_opt {
                      Some(v) => result[n.to_int().to_string()] = v
                      None => ()
                    }
                  _ => ()
                }
              _ => ()
            }
          }
          _ => ()
        }
      }
      Iterator::singleton(Json::object(result))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
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
    _ => raise TypeMismatch("object/array", json_type_name(input))
  }
}
