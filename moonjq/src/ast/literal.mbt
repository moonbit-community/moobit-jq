///|
/// Literal values in jq expressions
pub(all) enum Literal {
  Null
  Bool(Bool)
  Number(Double)
  String(String)
} derive(Show, Eq, ToJson)
