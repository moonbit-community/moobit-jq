///|
/// Evaluate MapValues
fn eval_map_values(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Object(obj) => {
      let result : Map[String, Json] = {}
      for key, value in obj {
        let transformed_results = eval_with_env(expr, value, env).collect()
        if not(transformed_results.is_empty()) {
          result[key] = transformed_results[0]
        }
      }
      Iterator::singleton(Json::object(result))
    }
    _ => raise TypeMismatch("object", json_type_name(input))
  }
}

///|
/// Evaluate RangeFromTo
fn eval_range_from_to(
  from_expr : Expr,
  to_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let from_results = eval_with_env(from_expr, input, env).collect()
  let to_results = eval_with_env(to_expr, input, env).collect()
  if from_results.is_empty() || to_results.is_empty() {
    return Iterator::empty()
  }
  match (from_results[0], to_results[0]) {
    (Number(from_num, ..), Number(to_num, ..)) => {
      let from_int = from_num.to_int()
      let to_int = to_num.to_int()
      let results : Array[Json] = []
      for i = from_int; i < to_int; i = i + 1 {
        results.push(Json::number(i.to_double()))
      }
      results.iterator()
    }
    _ => raise TypeMismatch("numbers", "non-numbers")
  }
}

///|
/// Evaluate RangeWithStep
fn eval_range_with_step(
  from_expr : Expr,
  to_expr : Expr,
  step_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let from_results = eval_with_env(from_expr, input, env).collect()
  let to_results = eval_with_env(to_expr, input, env).collect()
  let step_results = eval_with_env(step_expr, input, env).collect()
  if from_results.is_empty() || to_results.is_empty() || step_results.is_empty() {
    return Iterator::empty()
  }
  match (from_results[0], to_results[0], step_results[0]) {
    (Number(from_num, ..), Number(to_num, ..), Number(step_num, ..)) => {
      let from_int = from_num.to_int()
      let to_int = to_num.to_int()
      let step_int = step_num.to_int()
      let results : Array[Json] = []
      if step_int > 0 {
        let mut i = from_int
        while i < to_int {
          results.push(Json::number(i.to_double()))
          i = i + step_int
        }
      } else if step_int < 0 {
        let mut i = from_int
        while i > to_int {
          results.push(Json::number(i.to_double()))
          i = i + step_int
        }
      }
      results.iterator()
    }
    _ => raise TypeMismatch("numbers", "non-numbers")
  }
}

///|
/// Evaluate FirstGen
fn eval_first_gen(
  gen_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  if gen_results.is_empty() {
    Iterator::empty()
  } else {
    Iterator::singleton(gen_results[0])
  }
}

///|
/// Evaluate LastGen
fn eval_last_gen(
  gen_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  if gen_results.is_empty() {
    Iterator::empty()
  } else {
    Iterator::singleton(gen_results[gen_results.length() - 1])
  }
}

///|
/// Evaluate Repeat
fn eval_repeat(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let values = eval_with_env(expr, input, env).collect()
  if values.is_empty() {
    return Iterator::empty()
  }
  let mut i = 0
  Iterator::new(fn() {
    let result = Some(values[i])
    i += 1
    if i >= values.length() {
      i = 0
    }
    result
  })
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

///|
/// Evaluate UniqueBy
fn eval_unique_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let seen : Map[String, Bool] = {}
      let results : Array[Json] = []
      for elem in arr {
        let key_results = eval_with_env(expr, elem, env).collect()
        if not(key_results.is_empty()) {
          let key = key_results[0].to_string()
          if not(seen.contains(key)) {
            seen[key] = true
            results.push(elem)
          }
        }
      }
      Iterator::singleton(Json::array(results))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate MinBy
fn eval_min_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if arr.is_empty() {
        Iterator::singleton(null)
      } else {
        let mut min_elem : Json = arr[0]
        let min_val_results = eval_with_env(expr, min_elem, env).collect()
        if min_val_results.is_empty() {
          return Iterator::singleton(null)
        }
        let mut min_val = min_val_results[0]
        for i = 1; i < arr.length(); i = i + 1 {
          let elem = arr[i]
          let val_results = eval_with_env(expr, elem, env).collect()
          if not(val_results.is_empty()) {
            let val = val_results[0]
            if compare_json(val, min_val) < 0 {
              min_val = val
              min_elem = elem
            }
          }
        }
        Iterator::singleton(min_elem)
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate MaxBy
fn eval_max_by(
  expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if arr.is_empty() {
        Iterator::singleton(null)
      } else {
        let mut max_elem : Json = arr[0]
        let max_val_results = eval_with_env(expr, max_elem, env).collect()
        if max_val_results.is_empty() {
          return Iterator::singleton(null)
        }
        let mut max_val = max_val_results[0]
        for i = 1; i < arr.length(); i = i + 1 {
          let elem = arr[i]
          let val_results = eval_with_env(expr, elem, env).collect()
          if not(val_results.is_empty()) {
            let val = val_results[0]
            if compare_json(val, max_val) > 0 {
              max_val = val
              max_elem = elem
            }
          }
        }
        Iterator::singleton(max_elem)
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate Combinations
fn eval_combinations(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let arrays : Array[Array[Json]] = []
      for elem in arr {
        match elem {
          Array(inner) => arrays.push(inner)
          _ => return Iterator::empty()
        }
      }
      if arrays.is_empty() {
        return Iterator::empty()
      }
      let mut results : Array[Array[Json]] = [[]]
      for arr_item in arrays {
        let new_results : Array[Array[Json]] = []
        for res in results {
          for item in arr_item {
            let new_res = res.copy()
            new_res.push(item)
            new_results.push(new_res)
          }
        }
        results = new_results
      }
      results.iterator().map(Json::array)
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate Transpose
fn eval_transpose(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let mut max_len = 0
      for elem in arr {
        match elem {
          Array(inner) =>
            if inner.length() > max_len {
              max_len = inner.length()
            }
          _ => ()
        }
      }
      let results : Array[Array[Json]] = []
      for col = 0; col < max_len; col = col + 1 {
        let row : Array[Json] = []
        for elem in arr {
          match elem {
            Array(inner) => if col < inner.length() { row.push(inner[col]) }
            _ => ()
          }
        }
        results.push(row)
      }
      Iterator::singleton(Json::array(results.map(Json::array)))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate AnyGen
fn eval_any_gen(
  gen_expr : Expr,
  cond_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  let mut found = false
  for gen_result in gen_results {
    let cond_results = eval_with_env(cond_expr, gen_result, env).collect()
    if not(cond_results.is_empty()) {
      match cond_results[0] {
        True => {
          found = true
          break
        }
        _ => ()
      }
    }
  }
  Iterator::singleton(Json::boolean(found))
}

///|
/// Evaluate AllGen
fn eval_all_gen(
  gen_expr : Expr,
  cond_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  let mut all_true = true
  for gen_result in gen_results {
    let cond_results = eval_with_env(cond_expr, gen_result, env).collect()
    if not(cond_results.is_empty()) {
      match cond_results[0] {
        True => ()
        _ => {
          all_true = false
          break
        }
      }
    } else {
      all_true = false
      break
    }
  }
  Iterator::singleton(Json::boolean(all_true))
}

///|
/// Evaluate Foreach
fn eval_foreach(
  gen_expr : Expr,
  var_name : String,
  init_expr : Expr,
  update_expr : Expr,
  extract_expr : Expr?,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let gen_results = eval_with_env(gen_expr, input, env).collect()
  let init_results = eval_with_env(init_expr, input, env).collect()
  if init_results.is_empty() {
    return Iterator::empty()
  }
  let mut accumulator = init_results[0]
  let results : Array[Json] = []
  for gen_result in gen_results {
    let mut new_env = Env::new()
    for key, value in env.bindings {
      new_env = new_env.set(key, value)
    }
    for key, value in env.functions {
      new_env = new_env.set_function(key, value.0, value.1)
    }
    new_env = new_env.set(var_name, gen_result)
    let update_results = eval_with_env(update_expr, accumulator, new_env).collect()
    if not(update_results.is_empty()) {
      accumulator = update_results[0]
      let output = match extract_expr {
        Some(extract) => {
          let extract_results = eval_with_env(extract, accumulator, new_env).collect()
          if extract_results.is_empty() {
            accumulator
          } else {
            extract_results[0]
          }
        }
        None => accumulator
      }
      results.push(output)
    }
  }
  results.iterator()
}

///|
/// Evaluate PathsWithFilter
fn eval_paths_with_filter(
  filter_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let results : Array[Array[String]] = []
  collect_paths_with_filter(input, [], filter_expr, env, results)
  results.iterator().map(path => Json::array(path.map(Json::string)))
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
