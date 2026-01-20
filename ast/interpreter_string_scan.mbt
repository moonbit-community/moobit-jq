///|
/// Evaluate Explode
fn eval_explode(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    String(s) => {
      let results = s
        .iter()
        .map(fn(char) { Json::number(char.to_int().to_double()) })
        .to_array()
      Iter::singleton(Json::array(results))
    }
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate Implode
fn eval_implode(input : Json) -> Iter[Json] raise InterpreterError {
  match input {
    Array(arr) => {
      let chars = arr.filter_map(fn(elem) {
        match elem {
          Number(n, ..) => Int::to_char(n.to_int())
          _ => None
        }
      })
      let result = String::from_array(chars[:])
      Iter::singleton(Json::string(result))
    }
    _ => raise TypeMismatch("array", @ast_internal.json_type_name(input))
  }
}

///|
/// Evaluate Scan
fn eval_scan(
  pattern : String,
  input : Json,
) -> Iter[Json] raise InterpreterError {
  match input {
    String(s) => {
      let results : Array[Json] = []
      let pattern_view = pattern[:]
      scan_matches(
        s,
        pattern,
        pattern_view,
        0,
        s.length(),
        pattern.length(),
        results,
      )
      results.iter()
    }
    _ => raise TypeMismatch("string", @ast_internal.json_type_name(input))
  }
}

///|
fn scan_matches(
  s : String,
  pattern : String,
  pattern_view : StringView,
  idx : Int,
  slen : Int,
  plen : Int,
  results : Array[Json],
) -> Unit {
  let mut pos = idx
  let last = slen - plen
  while pos <= last {
    let slice_result = s[pos:pos + plen] catch {
      _ => {
        pos = pos + 1
        continue
      }
    }
    if slice_result == pattern_view {
      results.push(Json::string(pattern))
      pos = pos + plen
    } else {
      pos = pos + 1
    }
  }
}
