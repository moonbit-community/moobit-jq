///|
fn parse_err(query : String) -> Bool {
  try @parser.parse(query) catch {
    _ => true
  } noraise {
    _ => false
  }
}

///|
test "coverage: parse errors for string-arg builtins" {
  assert_true(parse_err("test(1)"))
  assert_true(parse_err("match(1)"))
  assert_true(parse_err("capture(1)"))
  assert_true(parse_err("splits(1)"))
  assert_true(parse_err("scan(1)"))
}

///|
test "coverage: parse errors for sub/gsub argument types" {
  assert_true(parse_err("sub(1; \"x\")"))
  assert_true(parse_err("sub(\"x\"; 1)"))
  assert_true(parse_err("gsub(1; \"x\")"))
  assert_true(parse_err("gsub(\"x\"; 1)"))
}

///|
test "coverage: parse errors for reduce/foreach variable binding" {
  assert_true(parse_err("reduce .[] as x (0; . + $x)"))
  assert_true(parse_err("foreach .[] as x (0; . + $x)"))
}

///|
test "coverage: parse errors for function definitions" {
  assert_true(parse_err("def : .; ."))
  assert_true(parse_err("def f(1): .; f"))
  assert_true(parse_err("def f(a; 1): .; f(1;2)"))
}

///|
test "coverage: parse errors for limit argument" {
  assert_true(parse_err("limit(\"2\"; .)"))
}

///|
test "coverage: parse errors for as and index edge cases" {
  assert_true(parse_err(". as 1 | ."))
  assert_true(parse_err(".[,]"))
  assert_true(parse_err(".[1,]"))
  assert_true(parse_err(".[-]"))
}

///|
test "coverage: parse errors for builtin argument validation" {
  assert_true(parse_err("split(1)"))
  assert_true(parse_err("join(1)"))
  assert_true(parse_err("startswith(1)"))
  assert_true(parse_err("endswith(1)"))
  assert_true(parse_err("has(true)"))
  assert_true(parse_err("range(.a)"))
  assert_true(parse_err("any(.[])"))
  assert_true(parse_err("all(.[])"))
  assert_true(parse_err("ltrimstr(1)"))
  assert_true(parse_err("rtrimstr(1)"))
  assert_true(parse_err("nth(\"x\")"))
}

///|
test "coverage: parse errors for reduce/foreach missing as" {
  assert_true(parse_err("reduce .[] (0; . + $x)"))
  assert_true(parse_err("foreach .[] (0; . + $x)"))
}
