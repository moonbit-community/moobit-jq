///|
/// Token types for jq lexer
pub(all) enum Token {
  // Literals
  TNumber(Double)
  TString(String)
  TStringInterpolation(Array[(String, String?)]) // parts with optional expressions
  TTrue
  TFalse
  TNull
  TIdentifier(String)
  TVariable(String) // $name
  TFormat(String) // @base64, @uri, etc.
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
  TAddAssign // +=
  TSubAssign // -=
  TMulAssign // *=
  TDivAssign // /=
  TModAssign // %=
  TAltAssign // //=
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
