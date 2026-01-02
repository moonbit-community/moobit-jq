///|
test "wb: set_at_path empty path" {
  let value = Json::number(3.0)
  let result = set_at_path(null, [], value)
  @json.inspect(result, content=3)
}
