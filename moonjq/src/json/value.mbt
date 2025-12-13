///|
/// Get the type name of a JSON value
/// The standard library Json type is automatically available
pub fn type_name(json : Json) -> String {
  match json {
    Null => "null"
    True | False => "boolean"
    Number(_) => "number"
    String(_) => "string"
    Array(_) => "array"
    Object(_) => "object"
  }
}

///|
/// Parse a JSON string into a Json value
pub fn parse(s : String) -> Json raise {
  @json.parse(s[:])
}
