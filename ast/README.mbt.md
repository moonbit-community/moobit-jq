# ast

Abstract Syntax Tree definitions and streaming interpreter for jq expressions.

## Overview

This package provides:

1. **AST Types**: Enum definitions for jq expressions, literals, and operators
2. **Interpreter**: A streaming evaluator that processes expressions against JSON input
3. **Error Types**: Structured errors for runtime evaluation failures

The interpreter uses lazy evaluation via `Iter[Json]` to enable efficient streaming of results without loading everything into memory.

## Public Functions

### eval

```moonbit nocheck
pub fn eval(expr : Expr, input : Json) -> Iter[Json] raise
```

Evaluate a jq expression against JSON input, returning an iterator of results.

**Parameters:**
- `expr`: The parsed jq expression (from `@parser.parse`)
- `input`: The JSON value to query

**Returns:**
- An `Iter[Json]` that lazily produces results

**Raises:**
- `InterpreterError` on evaluation failures (type mismatches, missing keys, etc.)

**Example:**
```moonbit nocheck
let expr = @parser.parse(".users[] | .name")
let input = @json.parse("{\"users\": [{\"name\": \"Alice\"}, {\"name\": \"Bob\"}]}")
for name in @ast.eval(expr, input) {
  println(name)  // "Alice", then "Bob"
}
```

## Types

### Expr

```moonbit nocheck
pub(all) enum Expr
```

The expression AST representing all jq constructs. Key variants include:

#### Core Expressions
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Identity` | `.` | Returns input unchanged |
| `Literal(Literal)` | `null`, `true`, `123`, `"str"` | Literal values |
| `Pipe(Expr, Expr)` | `expr \| expr` | Pipeline composition |
| `Comma(Expr, Expr)` | `expr, expr` | Multiple outputs |

#### Access Expressions
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Key(String)` | `.foo` | Object field access |
| `Index(Array[Int])` | `.[0]`, `.[]` | Array indexing/iteration |
| `Slice(Int?, Int?)` | `.[2:4]` | Array slicing |
| `Optional(Expr)` | `expr?` | Suppress errors |
| `Recurse` | `..` | Recursive descent |

#### Constructors
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `ArrayConstruct(Expr?)` | `[expr]`, `[]` | Build arrays |
| `ObjectConstruct(Array[(Expr, Expr?)])` | `{key: value}` | Build objects |

#### Binary Operations
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Operation(Expr, BinaryOp, Expr)` | `a + b`, `a == b` | Binary operations |
| `Alternative(Expr, Expr)` | `a // b` | Alternative (default) |

#### Built-in Functions
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Length` | `length` | String/array/object length |
| `Keys` | `keys` | Object keys or array indices |
| `Values` | `values` | Object values |
| `Type` | `type` | Type name as string |
| `Empty` | `empty` | Produce no output |
| `Not` | `not` | Boolean negation |

#### Array Functions
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Map(Expr)` | `map(expr)` | Transform each element |
| `Select(Expr)` | `select(expr)` | Filter elements |
| `Sort` | `sort` | Sort array |
| `SortBy(Expr)` | `sort_by(expr)` | Sort by key |
| `Reverse` | `reverse` | Reverse array |
| `Flatten(Int?)` | `flatten`, `flatten(n)` | Flatten nested arrays |
| `Unique` | `unique` | Remove duplicates |
| `UniqueBy(Expr)` | `unique_by(expr)` | Unique by key |
| `GroupBy(Expr)` | `group_by(expr)` | Group by key |
| `Combinations` | `combinations` | Cartesian product |
| `Transpose` | `transpose` | Matrix transpose |

#### Numeric Functions
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Add` | `add` | Sum array elements |
| `Min` / `Max` | `min`, `max` | Array min/max |
| `MinBy(Expr)` / `MaxBy(Expr)` | `min_by(expr)`, `max_by(expr)` | Min/max by key |
| `Floor` / `Round` / `Ceil` | `floor`, `round`, `ceil` | Rounding |
| `Abs` | `abs` | Absolute value |
| `Sqrt` | `sqrt` | Square root |
| `Pow(Expr)` | `pow(exp)` | Exponentiation |
| `Log` / `Exp` | `log`, `exp` | Natural log/exponential |
| `Sin` / `Cos` / `Tan` | `sin`, `cos`, `tan` | Trigonometry |
| `Asin` / `Acos` / `Atan` | `asin`, `acos`, `atan` | Inverse trig |

#### String Functions
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Split(String)` | `split(sep)` | Split string |
| `Join(String)` | `join(sep)` | Join array |
| `StartsWith(String)` | `startswith(str)` | Prefix check |
| `EndsWith(String)` | `endswith(str)` | Suffix check |
| `Contains(Expr)` | `contains(val)` | Containment check |
| `LTrimStr(String)` | `ltrimstr(str)` | Remove prefix |
| `RTrimStr(String)` | `rtrimstr(str)` | Remove suffix |
| `AsciiUpcase` / `AsciiDowncase` | `ascii_upcase`, `ascii_downcase` | Case conversion |
| `Explode` | `explode` | String to codepoints |
| `Implode` | `implode` | Codepoints to string |

#### Object Functions
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Has(String)` | `has(key)` | Key existence check |
| `In(Expr)` | `in(obj)` | Check if input is key in obj |
| `ToEntries` | `to_entries` | Object to key-value pairs |
| `FromEntries` | `from_entries` | Key-value pairs to object |
| `WithEntries(Expr)` | `with_entries(expr)` | Transform entries |
| `MapValues(Expr)` | `map_values(expr)` | Transform values |

#### Control Flow
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `IfThenElse(Expr, Expr, Expr)` | `if c then a else b end` | Conditional |
| `TryCatch(Expr, Expr?)` | `try expr catch handler` | Error handling |
| `Limit(Int, Expr)` | `limit(n; expr)` | Limit output count |
| `Until(Expr, Expr)` | `until(cond; update)` | Loop until condition |
| `While(Expr, Expr)` | `while(cond; update)` | Loop while condition |

#### Variables and Iteration
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Variable(String)` | `$var` | Variable reference |
| `As(Expr, String, Expr)` | `expr as $v \| body` | Variable binding |
| `Reduce(Expr, String, Expr, Expr)` | `reduce expr as $v (init; update)` | Fold/reduce |
| `Foreach(...)` | `foreach expr as $v (init; update; extract)` | Stateful iteration |

#### Path Functions
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Path(Expr)` | `path(expr)` | Get path to value |
| `Paths` | `paths` | All paths in input |
| `PathsWithFilter(Expr)` | `paths(filter)` | Filtered paths |
| `LeafPaths` | `leaf_paths` | Paths to leaf values |
| `GetPath(Expr)` | `getpath(path)` | Get value at path |
| `SetPath(Expr, Expr)` | `setpath(path; value)` | Set value at path |
| `DelPaths(Expr)` | `delpaths(paths)` | Delete paths |

#### Assignment
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Update(Expr, Expr)` | `path \|= expr` | Update in place |
| `Assign(Expr, Expr)` | `path = expr` | Assign value |
| `AddAssign(Expr, Expr)` | `path += expr` | Add and assign |
| `SubAssign(Expr, Expr)` | `path -= expr` | Subtract and assign |
| `MulAssign(Expr, Expr)` | `path *= expr` | Multiply and assign |
| `DivAssign(Expr, Expr)` | `path /= expr` | Divide and assign |
| `ModAssign(Expr, Expr)` | `path %= expr` | Modulo and assign |
| `AltAssign(Expr, Expr)` | `path //= expr` | Alternative assign |

#### Format Strings
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Format(String)` | `@base64`, `@uri`, `@csv`, `@html` | Format encodings |
| `StringInterpolation(...)` | `"text \(expr) more"` | String interpolation |

#### User-defined Functions
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `FunctionDef(String, Array[String], Expr)` | `def name(params): body;` | Define function |
| `FunctionCall(String, Array[Expr])` | `name(args)` | Call function |

#### Regex (Simple Implementation)
| Variant | jq Syntax | Description |
|---------|-----------|-------------|
| `Test(String)` | `test(regex)` | Test if matches |
| `Match(String)` | `match(regex)` | Get match info |
| `Capture(String)` | `capture(regex)` | Capture groups |
| `Scan(String)` | `scan(regex)` | Extract all matches |
| `Splits(String)` | `splits(regex)` | Split by regex |
| `Sub(String, String)` | `sub(regex; repl)` | Replace first |
| `GSub(String, String)` | `gsub(regex; repl)` | Replace all |

### Literal

```moonbit nocheck
///|
pub(all) enum Literal {
  Null
  Bool(Bool)
  Number(Double)
  String(String)
}
```

Literal values that can appear in jq expressions.

### BinaryOp

```moonbit nocheck
///|
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
}
```

Binary operators for arithmetic, comparison, and logical operations.

### InterpreterError

```moonbit nocheck
///|
pub(all) suberror InterpreterError {
  TypeMismatch(String, String) // (expected, got)
  KeyNotFound(String)
  IndexOutOfBounds(Int)
  InvalidOperation(String)
  DivisionByZero
  TypeError(String)
  EvalError(String)
}
```

Runtime errors during expression evaluation:

| Variant | Description |
|---------|-------------|
| `TypeMismatch(expected, got)` | Operation received wrong type |
| `KeyNotFound(key)` | Object key does not exist |
| `IndexOutOfBounds(idx)` | Array index out of range |
| `InvalidOperation(msg)` | Operation not supported for types |
| `DivisionByZero` | Division or modulo by zero |
| `TypeError(msg)` | General type error |
| `EvalError(msg)` | General evaluation error |

## Streaming Semantics

The interpreter uses `Iter[Json]` for lazy evaluation:

```moonbit nocheck
// Results are computed on-demand
let results = @ast.eval(expr, input)

// Only computes what's needed
for r in results.take(5) {
  println(r)
}

// Collect all results when needed
let all_results = results.collect()
```

This enables efficient processing of queries that produce many results without loading everything into memory.

## Internal Structure

The package is organized into multiple files:

- `expression.mbt` - Expr enum definition
- `literal.mbt` - Literal enum and conversion
- `operator.mbt` - BinaryOp enum
- `interpreter.mbt` - Main eval function and dispatch
- `interpreter_*.mbt` - Specialized evaluators for different expression types
- `interpreter_error.mbt` - Error type definitions
