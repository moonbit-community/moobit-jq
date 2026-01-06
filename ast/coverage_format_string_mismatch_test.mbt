///|
test "coverage: format errors" {
  assert_true((try? coverage_eval("@base64", "1")) is Err(_))
  assert_true((try? coverage_eval("@base64d", "1")) is Err(_))
  assert_true((try? coverage_eval("@csv", "1")) is Err(_))
  assert_true((try? coverage_eval("@html", "1")) is Err(_))
  assert_true((try? coverage_eval("@wat", "\"x\"")) is Err(_))
}

///|
test "coverage: string builtins mismatches" {
  assert_true((try? coverage_eval("startswith(\"a\")", "1")) is Err(_))
  assert_true((try? coverage_eval("endswith(\"a\")", "1")) is Err(_))
  assert_true((try? coverage_eval("split(\",\")", "1")) is Err(_))
  assert_true((try? coverage_eval("join(\",\")", "1")) is Err(_))
  @json.inspect(coverage_eval("join(\",\")", "[1, \"a\"]"), content=[
    "Number(1),a",
  ])
  @json.inspect(coverage_eval("contains(empty)", "\"abc\""), content=[false])
  assert_true((try? coverage_eval("ltrimstr(\"a\")", "1")) is Err(_))
  assert_true((try? coverage_eval("rtrimstr(\"a\")", "1")) is Err(_))
  assert_true((try? coverage_eval("ascii_upcase", "1")) is Err(_))
  assert_true((try? coverage_eval("ascii_downcase", "1")) is Err(_))
}
