# MoonJQ — jq in MoonBit

[![Test Status](https://img.shields.io/badge/tests-415%20passing-brightgreen)](https://github.com/moonbit-community/moobit-jq)
[![MoonBit](https://img.shields.io/badge/language-MoonBit-blue)](https://www.moonbitlang.com/)

MoonJQ is a high-performance, jq-compatible JSON query interpreter written in MoonBit. It implements a complete pipeline: **lexer → parser → streaming interpreter** with lazy evaluation using `Iterator[Json]`.

## Why MoonJQ?

- **Streaming semantics** - Process large JSON with constant memory via iterators
- **jq-compatible** - Familiar syntax and behavior for jq users
- **Type-safe** - Built with MoonBit's strong type system
- **Well-tested** - 415+ passing tests covering core jq functionality
- **Documented** - All code examples in this README are type-checked and tested

## Features

### Core Operations
- **Identity & Access**: `.` (identity), `.foo` (field), `.[0]` (index), `.[-1]` (negative index)
- **Iteration**: `.[]` (array iteration), `.[2:4]` (slicing), `..` (recursive descent)
- **Composition**: `|` (pipe), `,` (comma/multiple outputs)
- **Safety**: `?` (optional access), `//` (alternative/default)

### Operators
- **Arithmetic**: `+` (add/concat), `-` (subtract), `*` (multiply/repeat), `/` (divide), `%` (modulo)
- **Comparison**: `==`, `!=`, `<`, `<=`, `>`, `>=`
- **Logical**: `and`, `or`, `not`
- **Type coercion**: Automatic for arithmetic operations

### Control Flow
- **Conditionals**: `if ... then ... else ... end`
- **Error handling**: `try ... catch ...`
- **Variables**: `$var` (read-only bindings)

### Built-in Functions
- **Transformation**: `map(expr)`, `select(expr)`, `sort`, `reverse`, `flatten`, `flatten(n)`, `unique`
- **Aggregation**: `add`, `min`, `max`, `length`
- **Inspection**: `type`, `keys`, `values`
- **Math**: `floor`, `sqrt`
- **Utility**: `empty`, `not`

### Construction
- **Arrays**: `[expr]`, `[]` (empty)
- **Objects**: `{key: value}`, `{}` (empty)

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/moonbit-community/moobit-jq.git
cd moobit-jq

# Run tests to verify installation
moon test
```

### Basic Usage

Use the `jq` helper function to evaluate queries:

```mbt check
///|
/// Helper function: Evaluate a jq query and return newline-separated results.
/// This mimics the command-line jq tool's behavior.
fn jq(query : String, input : String) -> String raise {
  let expr = @parser.parse(query)
  let json = @moonjq_json.parse(input)
  @ast.eval(expr, json).collect().map(fn(v) { v.to_string() }).join("\n")
}
```

## Examples

All examples below are executable and type-checked by `moon check README.mbt.md`.

### 1. Filter and Project

Extract specific fields from objects that meet criteria:

  inspect(
    jq(query, input),
    content=(
      #|Object({"name": String("Alice"), "email": String("alice@example.com")})
    ),
  )
}
```

**Explanation**: The `select(.age >= 18)` filters users 18 or older, then `{name: .name, email: .email}` constructs new objects with only those fields.

### 2. Optional Access with Defaults

Handle missing fields gracefully using `?` and `//`:

```mbt check
  inspect(
    jq(query, input),
    content=(
      #|String("(unknown)")
    ),
  )
}
```

**Explanation**: The `?` operator prevents errors when `.user.name` doesn't exist, and `//` provides a default value.

### 3. Transform and Aggregate

  inspect(jq(query, input), content="Number(12)")
}
```

**Explanation**: `map(. * 2)` doubles each number, then `add` sums them all: `(1*2 + 2*2 + 3*2) = 12`.

### 4. Filter Logs by Level

Extract specific log messages based on severity:

```mbt check
///|
test "readme: extract error messages" {

///|
  inspect(
    jq(query, input),
    content=(
      #|String("disk full")
      #|String("timeout")
    ),
  )
}
```

**Explanation**: Streaming semantics produce multiple outputs. Each error-level event produces one result.

### 5. Array Slicing and Manipulation

Work with array subsets using slicing:

```mbt check
///|
test "readme: array slicing" {
  let query = ".items[1:3] | reverse"
  let input =
    #|{ "items": [10, 20, 30, 40, 50] }
  inspect(
    jq(query, input),
    content=(
      #|Array([Number(30), Number(20)])
    ),
  )
}
```

**Explanation**: `[1:3]` extracts elements at indices 1-2 (20, 30), then `reverse` flips the order.

### 6. Recursive Descent

Find all values at any depth using `..`:

```mbt check
///|
test "readme: recursive descent" {
  let query = ".. | select(type == \"number\")"
  let input =
    #|{
    #|  "a": 1,
    #|  "b": { "c": 2, "d": { "e": 3 } }
    #|}
  inspect(
    jq(query, input),
    content=(
      #|Number(1)
      #|Number(2)
      #|Number(3)
    ),
  )
}
```

**Explanation**: `..` recursively visits all values in the structure, then `select` filters only numbers.

## Project Structure

```
moobit-jq/
├── moon.mod.json          # Module metadata
├── README.mbt.md          # This file (executable documentation)
├── ast/                   # AST + streaming evaluator + integration tests
├── parser/                # Parser (includes lexer)
├── json/                  # JSON value wrapper
```

## Development

### Running Tests

```bash
# Run all tests (415+ tests)
moon test

# Run specific package tests
moon test -p parser
moon test -p ast
moon test -p json

# Type-check without running tests
moon check

# Type-check this README
moon check README.mbt.md

# Update test snapshots
moon test --update
```

### Code Quality

```bash
# Format code
moon fmt

# Generate package interfaces
moon info

# Check for warnings
moon check --target all
```

## Implementation Highlights

- **Streaming**: Uses MoonBit's `Iterator` for lazy evaluation and constant memory
- **Parser**: Hand-written recursive-descent parser with precedence climbing
- **Error handling**: Leverages MoonBit's checked error system with `raise`
- **Testing**: 415+ tests using MoonBit's snapshot testing (`inspect`)

## Limitations & Roadmap

See [FEATURES.md](FEATURES.md) for detailed feature status.

**Not yet implemented**:
- Variable binding with `as` patterns
- `reduce` expressions
- `sort_by`, `group_by`
- Assignment operators (`|=`, `=`)
- String interpolation (`\(expr)`)
- Many string/array utility functions

Contributions welcome!

## License

See [LICENSE](LICENSE).

## Acknowledgments

- Inspired by [jq](https://jqlang.github.io/jq/) by Stephen Dolan
- Built with [MoonBit](https://www.moonbitlang.com/)evel": "error", "message": "disk full" },
    #|    { "level": "error", "message": "timeout" }
    #|  ]
    #|}
  inspect(
    jq(query, input),
    content=(
      #|String("disk full")
      #|String("timeout")
    ),
  )
}
```

## Building and testing

This repo is a MoonBit module with multiple packages; run commands against specific package paths:

```bash
# Type-check a package (and its deps)
moon check --package-path parser
moon check --package-path ast

# Run tests
moon test -p ast -p json -p parser

# Update snapshots (expect tests)
moon test -p ast -p json -p parser --update

# Generate/update public interfaces (.mbti)
moon info
```

## License

See `LICENSE`.
