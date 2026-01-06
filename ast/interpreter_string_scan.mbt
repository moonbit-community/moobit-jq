///|
/// Evaluate Explode
fn eval_explode(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    String(s) => {
      let results = s
        .iterator()
        .map(fn(char) { Json::number(char.to_int().to_double()) })
        .to_array()
      Iterator::singleton(Json::array(results))
    }
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate Implode
fn eval_implode(input : Json) -> Iterator[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let chars = arr.filter_map(fn(elem) {
        match elem {
          Number(n, ..) => Int::to_char(n.to_int())
          _ => None
        }
      })
      let result = String::from_array(chars[:])
      Iterator::singleton(Json::string(result))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
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
      scan_matches(s, pattern, 0, s.length(), pattern.length(), results)
      results.iterator()
    }
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
fn scan_matches(
  s : String,
  pattern : String,
  idx : Int,
  slen : Int,
  plen : Int,
  results : Array[Json],
) -> Unit {
  if idx > slen - plen {
    return
  }
  let slice_result = s[idx:idx + plen] catch {
      _ => {
        scan_matches(s, pattern, idx + 1, slen, plen, results)
        return
      }
    }
  if slice_result.to_string() == pattern {
    results.push(Json::string(pattern))
    scan_matches(s, pattern, idx + plen, slen, plen, results)
  } else {
    scan_matches(s, pattern, idx + 1, slen, plen, results)
  }
}
