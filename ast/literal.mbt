///|
/// Literal values in jq expressions
pub(all) enum Literal {
  Null
  Bool(Bool)
  Number(Double)
  String(String)
} derive(Show, Eq, ToJson)

///|
fn Literal::to_json(self : Literal) -> Json {
  match self {
    Null => null
    Bool(b) => Json::boolean(b)
    Number(n) => Json::number(n)
    String(s) => Json::string(s)
  }
}
