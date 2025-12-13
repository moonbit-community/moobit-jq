///|
/// Binary operators in jq
pub(all) enum BinaryOp {
  Add // +
  Subtract // -
  Multiply // *
  Divide // /
  Modulo // %
  Equal // ==
  NotEqual // !=
  LessThan // <
  LessEq // <=
  GreaterThan // >
  GreaterEq // >=
  And // and
  Or // or
} derive(Show, Eq, ToJson)
