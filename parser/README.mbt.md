# parser

Lexer and parser for jq query language. Transforms jq query strings into an Abstract Syntax Tree (AST) for evaluation.

## Overview

This package implements a complete jq parser pipeline:

1. **Lexer**: Tokenizes the input string into a stream of tokens
2. **Parser**: Builds an AST from tokens using recursive descent with precedence climbing

The parser handles the full jq syntax including operators, control flow, function definitions, and string interpolation.

## Public Functions

### parse

```moonbit nocheck
pub fn parse(input : String) -> @ast.Expr raise
```

Parse a jq query string into an AST expression. This is the main entry point for parsing.

**Parameters:**
- `input`: A jq query string (e.g., `.foo | map(. + 1)`)

**Returns:**
- An `@ast.Expr` representing the parsed query

**Raises:**
- `ParseError` if the query contains syntax errors
- `LexError` if the query contains invalid tokens

**Example:**
```moonbit nocheck
///|
let expr = @parser.parse(".users[] | .name")
```

### lex

```moonbit nocheck
pub fn lex(input : String) -> Array[Token] raise LexError
```

Tokenize a jq query string into an array of tokens. This is useful for debugging or building custom parsers.

**Parameters:**
- `input`: A jq query string

**Returns:**
- An array of `Token` values, always ending with `TEof`

**Raises:**
- `LexError` on invalid characters, unterminated strings, or invalid numbers

**Example:**
```moonbit nocheck
///|
let tokens = @parser.lex(".foo | .bar")
// [TDot, TIdentifier("foo"), TPipe, TDot, TIdentifier("bar"), TEof]
```

## Types

### Token

```moonbit nocheck
///|
pub(all) enum Token {
  // Literals
  TNumber(Double)
  TString(String)
  TStringInterpolation(Array[(String, String?)])
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
}
```

### LexError

```moonbit nocheck
///|
pub suberror LexError {
  UnexpectedChar(Int, Char) // Position and unexpected character
  UnterminatedString(Int) // Position where string started
  InvalidNumber(Int, String) // Position and invalid number text
  InvalidEscape(Int, Char) // Position and invalid escape character
}
```

Lexer errors indicate problems during tokenization:

| Variant | Description |
|---------|-------------|
| `UnexpectedChar(pos, char)` | Unexpected character at position |
| `UnterminatedString(pos)` | String literal not closed |
| `InvalidNumber(pos, text)` | Invalid number format |
| `InvalidEscape(pos, char)` | Invalid escape sequence in string |

### ParseError

```moonbit nocheck
///|
pub(all) suberror ParseError {
  UnexpectedToken(String, String) // (found, expected)
  UnexpectedEnd(String) // (expected)
  InvalidSyntax(String)
  InvalidExpression(String)
}
```

Parser errors indicate problems during AST construction:

| Variant | Description |
|---------|-------------|
| `UnexpectedToken(found, expected)` | Got unexpected token |
| `UnexpectedEnd(expected)` | Unexpected end of input |
| `InvalidSyntax(msg)` | General syntax error |
| `InvalidExpression(msg)` | Invalid expression |

## Supported Syntax

### Literals
- Numbers: `42`, `3.14`, `-1`
- Strings: `"hello"`, `"with\nescapes"`
- String interpolation: `"value: \(.x)"`
- Booleans: `true`, `false`
- Null: `null`

### Access
- Identity: `.`
- Field access: `.foo`, `.foo.bar`
- Index: `.[0]`, `.[-1]`
- Slice: `.[2:5]`, `.[:-1]`
- Optional: `.foo?`, `.[0]?`
- Recursive descent: `..`

### Operators
- Arithmetic: `+`, `-`, `*`, `/`, `%`
- Comparison: `==`, `!=`, `<`, `<=`, `>`, `>=`
- Logical: `and`, `or`, `not`
- Pipe: `|`
- Comma: `,`
- Alternative: `//`

### Control Flow
- Conditional: `if .x then .y else .z end`
- Try-catch: `try .x catch .y`

### Iteration
- Array iteration: `.[]`
- Reduce: `reduce .[] as $x (0; . + $x)`
- Foreach: `foreach .[] as $x (0; . + $x)`

### Construction
- Arrays: `[.x, .y]`, `[.[] | . * 2]`
- Objects: `{a: .x, b: .y}`, `{(.key): .value}`

### Functions
- Definition: `def double: . * 2;`
- With parameters: `def add(x; y): x + y;`
- Built-in calls: `map(.x)`, `select(.a > 0)`

### Variables
- Binding: `.x as $v | ...`
- Reference: `$v`
