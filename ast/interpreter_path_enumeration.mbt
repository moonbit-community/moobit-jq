///|
priv enum PathFrame {
  ObjectFrame(Iter2[String, Json], Bool)
  ArrayFrame(Array[Json], Int, Int, Bool)
}

///|
fn path_index_number(i : Int) -> Json {
  Json::number(i.to_double())
}

///|
fn path_index_string(i : Int) -> Json {
  Json::string(i.to_string())
}

///|
fn push_container_frame(
  stack : Array[PathFrame],
  value : Json,
  has_segment : Bool,
) -> Bool {
  match value {
    Object(obj) =>
      if obj.is_empty() {
        false
      } else {
        stack.push(ObjectFrame(obj.iter2(), has_segment))
        true
      }
    Array(arr) =>
      if arr.is_empty() {
        false
      } else {
        stack.push(ArrayFrame(arr, 0, arr.length(), has_segment))
        true
      }
    _ => false
  }
}

///|
/// Evaluate Paths
fn eval_paths(input : Json) -> Iter[Json] {
  iter_paths(input, false, path_index_number)
}

///|
/// Evaluate LeafPaths
fn eval_leaf_paths(input : Json) -> Iter[Json] {
  iter_paths(input, true, path_index_number)
}

///|
/// Evaluate PathsWithFilter
fn eval_paths_with_filter(
  filter_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] {
  iter_paths_with_filter(filter_expr, input, env)
}

///|
fn iter_paths(
  input : Json,
  leaf_only : Bool,
  index_segment : (Int) -> Json,
) -> Iter[Json] {
  let path : Array[Json] = []
  let stack_ref : Ref[Array[PathFrame]] = Ref::new([])
  let root_pending : Ref[Bool] = Ref::new(true)
  Iter::new(fn() {
    if root_pending.val {
      root_pending.val = false
      let root_has_children = push_container_frame(stack_ref.val, input, false)
      if leaf_only && not(root_has_children) {
        return Some(Json::array(path.copy()))
      }
    }
    while true {
      match stack_ref.val.pop() {
        None => return None
        Some(frame) =>
          match frame {
            ObjectFrame(iter, has_segment) =>
              match iter.next() {
                Some((key, val)) => {
                  stack_ref.val.push(ObjectFrame(iter, has_segment))
                  path.push(Json::string(key))
                  let pushed = push_container_frame(stack_ref.val, val, true)
                  if leaf_only {
                    if pushed {
                      continue
                    }
                    let result = Json::array(path.copy())
                    ignore(path.pop())
                    return Some(result)
                  }
                  let result = Json::array(path.copy())
                  if not(pushed) {
                    ignore(path.pop())
                  }
                  return Some(result)
                }
                None => {
                  if has_segment {
                    ignore(path.pop())
                  }
                  continue
                }
              }
            ArrayFrame(arr, idx, len, has_segment) =>
              if idx >= len {
                if has_segment {
                  ignore(path.pop())
                }
                continue
              } else {
                let value = arr[idx]
                stack_ref.val.push(ArrayFrame(arr, idx + 1, len, has_segment))
                path.push(index_segment(idx))
                let pushed = push_container_frame(stack_ref.val, value, true)
                if leaf_only {
                  if pushed {
                    continue
                  }
                  let result = Json::array(path.copy())
                  ignore(path.pop())
                  return Some(result)
                }
                let result = Json::array(path.copy())
                if not(pushed) {
                  ignore(path.pop())
                }
                return Some(result)
              }
          }
      }
    } else {
      None
    }
  })
}

///|
fn filter_matches(
  value : Json,
  filter_expr : Expr,
  env : Env,
) -> Bool? {
  let filter_results = eval_with_env(filter_expr, value, env) catch {
    _ => return None
  }
  let filter_results_arr = filter_results.collect()
  if filter_results_arr.is_empty() {
    Some(false)
  } else {
    match filter_results_arr[0] {
      True => Some(true)
      _ => Some(false)
    }
  }
}

///|
fn iter_paths_with_filter(
  filter_expr : Expr,
  input : Json,
  env : Env,
) -> Iter[Json] {
  let path : Array[Json] = []
  let stack_ref : Ref[Array[PathFrame]] = Ref::new([])
  let root_pending : Ref[Bool] = Ref::new(true)
  let done : Ref[Bool] = Ref::new(false)
  Iter::new(fn() {
    if done.val {
      return None
    }
    if root_pending.val {
      root_pending.val = false
      match filter_matches(input, filter_expr, env) {
        None => {
          done.val = true
          return None
        }
        Some(_) => ()
      }
      let root_has_children = push_container_frame(stack_ref.val, input, false)
      if not(root_has_children) {
        done.val = true
        return None
      }
    }
    while true {
      match stack_ref.val.pop() {
        None => return None
        Some(frame) =>
          match frame {
            ObjectFrame(iter, has_segment) =>
              match iter.next() {
                Some((key, val)) => {
                  stack_ref.val.push(ObjectFrame(iter, has_segment))
                  path.push(Json::string(key))
                  match filter_matches(val, filter_expr, env) {
                    None => {
                      ignore(path.pop())
                      continue
                    }
                    Some(matches) => {
                      let pushed = push_container_frame(stack_ref.val, val, true)
                      if matches {
                        let result = Json::array(path.copy())
                        if not(pushed) {
                          ignore(path.pop())
                        }
                        return Some(result)
                      }
                      if not(pushed) {
                        ignore(path.pop())
                      }
                      continue
                    }
                  }
                }
                None => {
                  if has_segment {
                    ignore(path.pop())
                  }
                  continue
                }
              }
            ArrayFrame(arr, idx, len, has_segment) =>
              if idx >= len {
                if has_segment {
                  ignore(path.pop())
                }
                continue
              } else {
                let value = arr[idx]
                stack_ref.val.push(ArrayFrame(arr, idx + 1, len, has_segment))
                path.push(path_index_string(idx))
                match filter_matches(value, filter_expr, env) {
                  None => {
                    ignore(path.pop())
                    continue
                  }
                  Some(matches) => {
                    let pushed = push_container_frame(stack_ref.val, value, true)
                    if matches {
                      let result = Json::array(path.copy())
                      if not(pushed) {
                        ignore(path.pop())
                      }
                      return Some(result)
                    }
                    if not(pushed) {
                      ignore(path.pop())
                    }
                    continue
                  }
                }
              }
          }
      }
    } else {
      None
    }
  })
}
