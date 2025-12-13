# jq Implementation in MoonBit - Implementation Plan

## Overview

This document outlines the plan to implement a subset of jq in MoonBit, inspired by:
- **query-json**: A Reason/OCaml implementation (simpler, good for understanding the structure)
- **jq**: The authoritative C implementation (comprehensive test suite, full feature set)

The goal is to create a pure functional implementation, leaving out I/O operations initially.

---

## Architecture

```
.
├── moon.mod.json              # Module descriptor
├── README.md                  # Project README
├── FEATURES.md                # Feature checklist
├── PROGRESS.md                # Project notes
└── src/                       # MoonBit source (module "source" dir)
    ├── ast/                   # AST type definitions
    ├── json/                  # JSON helpers
    ├── lexer/                 # Tokenizer
    ├── parser/                # Parser
    ├── interpreter/           # Interpreter/Evaluator
    └── integration/           # End-to-end tests
```

---

## Phase 1: Core Data Types

### 1.1 JSON Value Type (`json/value.mbt`)

```moonbit
///|
pub enum Json {
  Null
  Bool(Bool)
  Number(Double)
  String(String)
  Array(Array[Json])
  Object(Map[String, Json])
} derive(Show, Eq, ToJson)
```

Key operations needed:
- `Json::from_string(s: String) -> Json raise` - Parse JSON string
- `Json::to_string(self: Json) -> String` - Serialize to JSON string
- `Json::type_name(self: Json) -> String` - Get type as string ("null", "boolean", etc.)

### 1.2 Literal Type (`ast/literal.mbt`)

```moonbit
///|
pub enum Literal {
  Null
  Bool(Bool)
  Number(Double)
  String(String)
} derive(Show, Eq)
```

### 1.3 Operators (`ast/operator.mbt`)

```moonbit
///|
pub enum BinaryOp {
  Add         // +
  Subtract    // -
  Multiply    // *
  Divide      // /
  Modulo      // %
  Equal       // ==
  NotEqual    // !=
  LessThan    // <
  LessEq      // <=
  GreaterThan // >
  GreaterEq   // >=
  And         // and
  Or          // or
} derive(Show, Eq)
```

---

## Phase 2: AST Definition

### 2.1 Expression Types (`ast/expression.mbt`)

Based on query-json's AST, prioritized by importance:

**Core expressions (Phase 2a):**
```moonbit
///|
pub enum Expr {
  // Core
  Identity                                    // .
  Literal(Literal)                            // null, true, 123, "str"
  Pipe(Expr, Expr)                            // expr | expr
  Comma(Expr, Expr)                           // expr, expr
  
  // Access
  Key(String)                                 // .foo
  Index(Array[Int])                           // .[0], .[1,2,3], .[] (empty = iterator)
  Slice(Int?, Int?)                           // .[2:4], .[2:], .[:4]
  Optional(Expr)                              // expr?
  
  // Constructors
  ArrayConstruct(Expr?)                       // [expr] or []
  ObjectConstruct(Array[(Expr, Expr?)])       // {key: value, ...}
  
  // Operations
  Operation(Expr, BinaryOp, Expr)             // expr op expr
} derive(Show, Eq)
```

**Built-in functions (Phase 2b):**
```moonbit
  // Built-ins (add incrementally)
  Length                                      // length
  Keys                                        // keys
  Values                                      // values
  Type                                        // type
  Empty                                       // empty
  Not                                         // not
  
  // Array/Object functions
  Map(Expr)                                   // map(expr)
  Select(Expr)                                // select(expr)
  Sort                                        // sort
  SortBy(Expr)                                // sort_by(expr)
  Reverse                                     // reverse
  Flatten(Int?)                               // flatten, flatten(n)
  Unique                                      // unique
  GroupBy(Expr)                               // group_by(expr)
  
  // Numeric
  Add                                         // add (sum array)
  Floor                                       // floor
  Sqrt                                        // sqrt
  Min                                         // min
  Max                                         // max
```

**Control flow (Phase 2c):**
```moonbit
  // Control flow
  IfThenElse(Expr, Expr, Expr)                // if cond then a else b end
  TryCatch(Expr, Expr?)                       // try expr catch handler
  
  // Variables and Reduce
  Variable(String)                            // $var
  As(Expr, String, Expr)                      // expr as $var | expr
  Reduce(Expr, String, Expr, Expr)            // reduce expr as $var (init; update)
  
  // Advanced
  Recurse                                     // recurse, ..
  RecurseWith(Expr, Expr)                     // recurse(f; cond)
  Walk(Expr)                                  // walk(expr)
  Path(Expr)                                  // path(expr)
  
  // Assignment
  Update(Expr, Expr)                          // |=
  Assign(Expr, Expr)                          // =
  Alternative(Expr, Expr)                     // //
```

---

## Phase 3: Lexer

### 3.1 Token Types (`lexer/token.mbt`)

```moonbit
///|
pub enum Token {
  // Literals
  TNumber(Double)
  TString(String)
  TBool(Bool)
  TNull
  TIdentifier(String)
  TVariable(String)          // $name
  
  // Operators
  TDot                       // .
  TDotDot                    // ..
  TPipe                      // |
  TComma                     // ,
  TColon                     // :
  TSemicolon                 // ;
  TQuestion                  // ?
  
  // Brackets
  TLParen                    // (
  TRParen                    // )
  TLBracket                  // [
  TRBracket                  // ]
  TLBrace                    // {
  TRBrace                    // }
  
  // Arithmetic
  TPlus                      // +
  TMinus                     // -
  TStar                      // *
  TSlash                     // /
  TPercent                   // %
  
  // Comparison
  TEq                        // ==
  TNeq                       // !=
  TLt                        // <
  TLe                        // <=
  TGt                        // >
  TGe                        // >=
  
  // Assignment
  TAssign                    // =
  TUpdate                    // |=
  TAlternative               // //
  
  // Keywords
  TAnd                       // and
  TOr                        // or
  TNot                       // not
  TIf                        // if
  TThen                      // then
  TElse                      // else
  TElif                      // elif
  TEnd                       // end
  TAs                        // as
  TReduce                    // reduce
  TForeach                   // foreach
  TTry                       // try
  TCatch                     // catch
  TDef                       // def
  
  TEof
} derive(Show, Eq)
```

### 3.2 Lexer Implementation (`lexer/lexer.mbt`)

```moonbit
///|
pub fn lex(input: String) -> Array[Token] raise LexerError {
  // Character-by-character lexing
  // Handle:
  // - Whitespace skipping
  // - Number literals (including negative, decimals, scientific)
  // - String literals (with escape sequences)
  // - Identifiers and keywords
  // - Operators (single and multi-character)
  // - Comments (optional: # to end of line)
  ...
}
```

---

## Phase 4: Parser

### 4.1 Parser Implementation (`parser/parser.mbt`)

Recursive descent parser with operator precedence handling:

**Precedence (low to high):**
1. `|`, `|=`, `//` (pipe, update, alternative)
2. `,` (comma)
3. `or`
4. `and`
5. `==`, `!=`, `<`, `<=`, `>`, `>=`
6. `+`, `-`
7. `*`, `/`, `%`

```moonbit
///|
pub fn parse(tokens: Array[Token]) -> Expr raise ParseError {
  let parser = Parser::new(tokens)
  parser.parse_expression()
}

///|
struct Parser {
  tokens: Array[Token]
  mut pos: Int
}

///|
fn Parser::parse_expression(self: Parser) -> Expr raise ParseError {
  self.parse_pipe()
}

///|
fn Parser::parse_pipe(self: Parser) -> Expr raise ParseError {
  // Parse left operand
  // While next token is | or |= or //
  //   Parse right operand and build Pipe/Update/Alternative
  ...
}
```

---

## Phase 5: Interpreter

### 5.1 Evaluation Context (`interpreter/context.mbt`)

```moonbit
///|
pub struct Context {
  variables: Map[String, Json]
}

///|
pub fn Context::new() -> Context {
  { variables: {} }
}

///|
pub fn Context::with_var(self: Context, name: String, value: Json) -> Context {
  let vars = self.variables
  vars[name] = value
  { variables: vars }
}
```

### 5.2 Evaluation Result

jq produces multiple outputs (generators), so we need to handle that:

```moonbit
///|
/// Evaluation produces zero or more Json values
pub fn eval(expr: Expr, input: Json, ctx: Context) -> Iter[Json] raise EvalError {
  match expr {
    Identity => Iter::singleton(input)
    Literal(lit) => Iter::singleton(literal_to_json(lit))
    Pipe(left, right) => {
      // For each result of left, evaluate right
      eval(left, input, ctx).flat_map(fn(v) { eval(right, v, ctx) })
    }
    Comma(left, right) => {
      // Concatenate results
      eval(left, input, ctx).concat(eval(right, input, ctx))
    }
    Key(k) => {
      match input {
        Object(obj) => Iter::singleton(obj.get(k).unwrap_or(Json::Null))
        _ => raise EvalError::TypeMismatch("object", input.type_name())
      }
    }
    // ... more cases
  }
}
```

### 5.3 Built-in Implementations (`interpreter/builtins.mbt`)

Implement common built-ins:

```moonbit
///|
fn builtin_length(input: Json) -> Json raise EvalError {
  match input {
    Null => Json::Number(0.0)
    String(s) => Json::Number(s.length().to_double())
    Array(arr) => Json::Number(arr.length().to_double())
    Object(obj) => Json::Number(obj.size().to_double())
    _ => raise EvalError::TypeMismatch("string/array/object/null", input.type_name())
  }
}

///|
fn builtin_keys(input: Json) -> Json raise EvalError {
  match input {
    Object(obj) => Json::Array(obj.keys().map(Json::String).to_array())
    Array(arr) => Json::Array(
      Array::makei(arr.length(), fn(i) { Json::Number(i.to_double()) })
    )
    _ => raise EvalError::TypeMismatch("object/array", input.type_name())
  }
}
```

---

## Phase 6: Testing Strategy

### 6.1 Unit Tests

Each module should have comprehensive tests:

```moonbit
///|
test "lexer: basic tokens" {
  let tokens = lex(".foo | .bar")
  inspect(tokens, content="[TDot, TIdentifier(\"foo\"), TPipe, TDot, TIdentifier(\"bar\")]")
}

///|
test "parser: pipe expression" {
  let expr = parse(".foo | .bar")
  inspect(expr, content="Pipe(Key(\"foo\"), Key(\"bar\"))")
}

///|
test "eval: identity" {
  let result = eval(Identity, Json::Number(42.0), Context::new())
  inspect(result.collect(), content="[Number(42)]")
}
```

### 6.2 Integration Tests

Port tests from jq's test suite (`jq/tests/man.test`, `jq/tests/jq.test`):

```moonbit
///|
fn run_jq(query: String, input: String) -> String raise {
  let json = Json::from_string(input)
  let expr = parse(lex(query))
  let results = eval(expr, json, Context::new()).collect()
  results.map(fn(j) { j.to_string() }).join("\n")
}

///|
test "jq: field access" {
  let result = run_jq(".foo", "{\"foo\": 42, \"bar\": 43}")
  inspect(result, content="42")
}

///|
test "jq: pipe" {
  let result = run_jq(".foo | .bar", "{\"foo\": {\"bar\": 42}}")
  inspect(result, content="42")
}
```

---

## Implementation Priorities

### Tier 1: Core (Essential)
1. JSON parsing and serialization
2. Identity (`.`)
3. Field access (`.foo`, `.["foo"]`)
4. Array index (`.[0]`, `.[-1]`)
5. Iterator (`.[]`)
6. Pipe (`|`)
7. Comma (`,`)
8. Array construction (`[...]`)
9. Object construction (`{...}`)
10. Basic arithmetic (`+`, `-`, `*`, `/`)
11. Comparison (`==`, `!=`, `<`, `>`, `<=`, `>=`)
12. `length`, `keys`, `type`

### Tier 2: Common Operations
1. `map(expr)`
2. `select(expr)`
3. `sort`, `sort_by(expr)`
4. `reverse`
5. `unique`
6. `flatten`
7. `add`
8. `if-then-else`
9. `and`, `or`, `not`
10. Optional operator (`?`)
11. Alternative operator (`//`)
12. Slicing (`.[2:4]`)

### Tier 3: Variables and Control Flow
1. Variables (`$var`)
2. `as` expressions
3. `reduce`
4. `try-catch`
5. `empty`
6. `error`

### Tier 4: Advanced
1. `recurse`, `..`
2. `walk`
3. `path`, `getpath`, `setpath`
4. `to_entries`, `from_entries`
5. `group_by`
6. `def` (user-defined functions)
7. String interpolation
8. Regular expressions

### Tier 5: Completeness (Optional)
1. Format strings (`@base64`, `@uri`, `@csv`, etc.)
2. Date functions
3. SQL-like operators
4. I/O functions (if needed)

---

## API Design

### Public API

```moonbit
///|
/// Parse and execute a jq query on JSON input
pub fn run(query: String, input: String) -> Result[Array[String], String] {
  try {
    let json = Json::from_string(input)
    let tokens = lex(query)
    let expr = parse(tokens)
    let results = eval(expr, json, Context::new())
    Ok(results.map(fn(j) { j.to_string() }).collect())
  } catch {
    e => Err(e.to_string())
  }
}

///|
/// Parse and execute, returning Json values
pub fn query(query: String, json: Json) -> Iter[Json] raise {
  let tokens = lex(query)
  let expr = parse(tokens)
  eval(expr, json, Context::new())
}
```

---

## Milestones

### Milestone 1: Hello jq
- [ ] JSON value type with basic operations
- [ ] Lexer for basic tokens
- [ ] Parser for `.`, `.foo`, `|`
- [ ] Interpreter for identity and field access
- [ ] First passing test: `.foo` on `{"foo": 42}`

### Milestone 2: Array Operations
- [ ] Array indexing and slicing
- [ ] Iterator `.[]`
- [ ] Array construction
- [ ] `map`, `select`
- [ ] Pass: All array tests from man.test

### Milestone 3: Full Expressions
- [ ] All operators (arithmetic, comparison, logical)
- [ ] Object construction
- [ ] `if-then-else`
- [ ] Common built-ins (`length`, `keys`, `type`, etc.)
- [ ] Pass: 50% of man.test

### Milestone 4: Variables and Control
- [ ] Variables and `as`
- [ ] `reduce`
- [ ] `try-catch`
- [ ] `empty`, `error`
- [ ] Pass: 75% of man.test

### Milestone 5: Advanced Features
- [ ] `recurse`, `..`
- [ ] Path operations
- [ ] User-defined functions (`def`)
- [ ] Pass: 90% of man.test

---

## Notes

### Differences from jq
1. No streaming I/O (pure functions only)
2. May use different floating-point precision
3. Error messages may differ
4. Some esoteric features may be omitted

### Key Implementation Decisions
1. **Generator model**: Use `Iter[Json]` for lazy evaluation of multiple results
2. **Error handling**: Use MoonBit's `raise` for errors
3. **Immutability**: JSON values are immutable; updates create new values
4. **Testing**: Heavy use of snapshot testing with `inspect()`

### References
- [jq Manual](https://jqlang.org/manual/)
- [jq Language Description](https://github.com/jqlang/jq/wiki/jq-Language-Description)
- [jq Implementation Paper](https://arxiv.org/pdf/2302.10576)
- [query-json source](https://github.com/davesnx/query-json)
