///|
/// Evaluate array sum
fn eval_add(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let mut sum = 0.0
      for elem in arr {
        match elem {
          Number(n, ..) => sum = sum + n
          _ => ()
        }
      }
      Iterator::singleton(Json::number(sum))
    }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate floor
fn eval_floor(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.floor()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate square root
fn eval_sqrt(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.sqrt()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate minimum over array
fn eval_min(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if arr.is_empty() {
        Iterator::singleton(null)
      } else {
        let mut min_val = arr[0]
        for elem in arr {
          if compare_json(elem, min_val) < 0 {
            min_val = elem
          }
        }
        Iterator::singleton(min_val)
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate maximum over array
fn eval_max(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) =>
      if arr.is_empty() {
        Iterator::singleton(null)
      } else {
        let mut max_val = arr[0]
        for elem in arr {
          if compare_json(elem, max_val) > 0 {
            max_val = elem
          }
        }
        Iterator::singleton(max_val)
      }
    _ => raise TypeMismatch("array", json_type_name(input))
  }
}

///|
/// Evaluate rounding
fn eval_round(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.round()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate ceiling
fn eval_ceil(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.ceil()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate absolute value
fn eval_abs(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(n.abs()))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate power
fn eval_pow(
  exp_expr : Expr,
  input : Json,
  env : Env,
) -> Iterator[Json] raise InterpreterError {
  let exp_results = eval_with_env(exp_expr, input, env).collect()
  if exp_results.is_empty() {
    return Iterator::singleton(null)
  }
  match (input, exp_results[0]) {
    (Number(base, ..), Number(exp, ..)) =>
      Iterator::singleton(Json::number(@math.pow(base, exp)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate natural log
fn eval_log(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.ln(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate exponent
fn eval_exp(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.exp(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate sine
fn eval_sin(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.sin(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate cosine
fn eval_cos(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.cos(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate tangent
fn eval_tan(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.tan(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate arcsine
fn eval_asin(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.asin(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate arccosine
fn eval_acos(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.acos(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}

///|
/// Evaluate arctangent
fn eval_atan(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Number(n, ..) => Iterator::singleton(Json::number(@math.atan(n)))
    _ => raise TypeMismatch("number", json_type_name(input))
  }
}
