///|
/// Token types for jq lexer
pub(all) enum Token {
  // Literals
  TNumber(Double)
  TString(String)
  TTrue
  TFalse
  TNull
  TIdentifier(String)
  TVariable(String) // $name
  // Operators
  TDot // .
  TDotDot // ..
  TPipe // |
  TComma // ,
  TColon // :
  TSemicolon // ;
  TQuestion // ?
  // Brackets
  TLParen // (
  TRParen // )
  TLBracket // [
  TRBracket // ]
  TLBrace // {
  TRBrace // }
  // Arithmetic
  TPlus // +
  TMinus // -
  TStar // *
  TSlash // /
  TPercent // %
  // Comparison
  TEq // ==
  TNeq // !=
  TLt // <
  TLe // <=
  TGt // >
  TGe // >=
  // Assignment
  TAssign // =
  TUpdate // |=
  TAlternative // //
  // Keywords
  TAnd // and
  TOr // or
  TNot // not
  TIf // if
  TThen // then
  TElse // else
  TElif // elif
  TEnd // end
  TAs // as
  TReduce // reduce
  TForeach // foreach
  TTry // try
  TCatch // catch
  TDef // def
  TEof
} derive(Show, Eq)
