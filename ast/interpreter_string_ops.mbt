///|
/// Evaluate string split
fn eval_split(sep : String, input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => {
      let parts = s.split(sep)
      let json_parts : Array[Json] = []
      for part in parts {
        json_parts.push(Json::string(part.to_string()))
      }
      Iterator::singleton(Json::array(json_parts))
    }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate string join
fn eval_join(sep : String, input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let parts : Array[String] = []
      for elem in arr {
        match elem {
          String(s) => parts.push(s)
          _ => parts.push(elem.to_string())
        }
      }
      Iterator::singleton(Json::string(parts.join(sep)))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
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
    _ => raise TypeMismatch("string", json_type_name(input))
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
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate contains for strings, arrays, and objects
fn eval_contains(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let needle_results = eval_with_env(expr, input, env).collect()
  if needle_results.is_empty() {
    return Iterator::singleton(Json::boolean(false))
  }
  let needle = needle_results[0]
  match (input, needle) {
    (String(haystack), String(n)) =>
      Iterator::singleton(Json::boolean(haystack.contains(n)))
    (Array(haystack), _) => {
      let mut found = false
      for elem in haystack {
        if elem == needle {
          found = true
          break
        }
      }
      Iterator::singleton(Json::boolean(found))
    }
    (Object(haystack), String(key)) =>
      Iterator::singleton(Json::boolean(haystack.contains(key)))
    _ => Iterator::singleton(Json::boolean(false))
  }
}

///|
/// Evaluate inside for strings, arrays, and objects
fn eval_inside(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let container_results = eval_with_env(expr, input, env).collect()
  if container_results.is_empty() {
    return Iterator::singleton(Json::boolean(false))
  }
  let container = container_results[0]
  match (input, container) {
    (String(needle), String(haystack)) =>
      Iterator::singleton(Json::boolean(haystack.contains(needle)))
    (Array(needle_arr), Array(haystack)) => {
      let mut all_found = true
      for needle_elem in needle_arr {
        let mut found = false
        for haystack_elem in haystack {
          if haystack_elem == needle_elem {
            found = true
            break
          }
        }
        if not(found) {
          all_found = false
          break
        }
      }
      Iterator::singleton(Json::boolean(all_found))
    }
    (String(key), Object(haystack)) =>
      Iterator::singleton(Json::boolean(haystack.contains(key)))
    _ => Iterator::singleton(Json::boolean(false))
  }
}

///|
/// Evaluate left trim
fn eval_ltrim_str(
  prefix : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) =>
      match s.strip_prefix(prefix[:]) {
        Some(rest) => Iterator::singleton(Json::string(rest.to_string()))
        None => Iterator::singleton(input)
      }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate right trim
fn eval_rtrim_str(
  suffix : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) =>
      match s.strip_suffix(suffix[:]) {
        Some(rest) => Iterator::singleton(Json::string(rest.to_string()))
        None => Iterator::singleton(input)
      }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate ASCII upcase
fn eval_ascii_upcase(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => {
      let result = @buffer.new()
      for ch in s {
        if ch >= 'a' && ch <= 'z' {
          result.write_char(Int::unsafe_to_char(ch.to_int() - 32))
        } else {
          result.write_char(ch)
        }
      }
      Iterator::singleton(Json::string(result.to_string()))
    }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate ASCII downcase
fn eval_ascii_downcase(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => {
      let result = @buffer.new()
      for ch in s {
        if ch >= 'A' && ch <= 'Z' {
          result.write_char(Int::unsafe_to_char(ch.to_int() + 32))
        } else {
          result.write_char(ch)
        }
      }
      Iterator::singleton(Json::string(result.to_string()))
    }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate Explode
fn eval_explode(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => {
      let results : Array[Json] = []
      for char in s {
        results.push(Json::number(char.to_int().to_double()))
      }
      Iterator::singleton(Json::array(results))
    }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}

///|
/// Evaluate Implode
fn eval_implode(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let buffer = @buffer.new()
      for elem in arr {
        match elem {
          Number(n, ..) => {
            let code = n.to_int()
            match Int::to_char(code) {
              Some(c) => buffer.write_char(c)
              None => ()
            }
          }
          _ => ()
        }
      }
      Iterator::singleton(Json::string(buffer.to_string()))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate Scan
fn eval_scan(
  pattern : String,
  input : Json,
) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => {
      let results : Array[Json] = []
      let slen = s.length()
      let plen = pattern.length()
      let mut i = 0
      while i <= slen - plen {
        let slice_result = s[i:i + plen] catch {
          _ => {
            i = i + 1
            continue
          }
        }
        if slice_result.to_string() == pattern {
          results.push(Json::string(pattern))
          i = i + plen
        } else {
          i = i + 1
        }
      }
      results.iterator()
    }
    _ => raise TypeMismatch("string", json_type_name(input))
  }
}
