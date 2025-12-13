# MoonJQ - A jq Implementation in MoonBit

A complete implementation of the jq JSON query language in MoonBit, featuring a lexer, parser, and interpreter with streaming semantics.

## Features

- ✅ **Complete jq core syntax**: Identity, field access, array operations, pipes, comma operator
- ✅ **Arithmetic operations**: `+`, `-`, `*`, `/`, `%` with type coercion (numbers, strings, arrays, objects)
- ✅ **Comparison operators**: `==`, `!=`, `<`, `<=`, `>`, `>=`
- ✅ **Logical operators**: `and`, `or`, `not`
- ✅ **Array/Object construction**: `[expr]`, `{key: expr}`
- ✅ **Control flow**: `if-then-else`, `try-catch`
- ✅ **Optional operator**: `?` to suppress errors
- ✅ **Alternative operator**: `//` for null coalescing
- ✅ **Recursive descent**: `..` to traverse nested structures
- ✅ **Built-in functions**: 
  - Array: `map`, `select`, `sort`, `reverse`, `flatten`, `unique`, `add`, `min`, `max`
  - Object: `keys`, `values`
  - General: `length`, `type`, `empty`, `not`
  - Numeric: `floor`, `sqrt`
- ✅ **Streaming semantics**: Multiple results via `Iterator[Json]`

## Project Structure

```
.
├── moon.mod.json
└── src/
    ├── ast/              # AST type definitions
    │   ├── expression.mbt
    │   ├── literal.mbt
    │   └── operator.mbt
    ├── json/             # JSON helper functions (stdlib wrapper)
    │   ├── value.mbt
    │   └── value_test.mbt
    ├── lexer/            # Tokenization
    │   ├── lexer.mbt
    │   ├── lexer_test.mbt
    │   └── token.mbt
    ├── parser/           # Parsing (recursive descent)
    │   ├── parser.mbt
    │   └── parser_test.mbt
    ├── interpreter/      # Evaluation with streaming
    │   ├── interpreter.mbt
    │   └── interpreter_test.mbt
    └── integration/      # End-to-end tests
        └── integration_test.mbt
```

## Testing

**136 tests passing** covering:
- 7 JSON tests
- 31 Lexer tests
- 52 Parser tests  
- 25 Interpreter tests
- 21 Integration tests

```bash
# Run all tests
moon test

# Run specific package tests
moon test src/lexer
moon test src/parser
moon test src/interpreter
moon test src/integration

# Update test snapshots
moon test --update
```

## Usage Example

```moonbit
let expr = @parser.parse(".users | .[] | select(.age > 18) | .name")
let json = @json.parse("{\"users\": [{\"name\": \"Alice\", \"age\": 25}]}")
let results = @interpreter.eval(expr, json).collect()
// results: [String("Alice")]
```

## Architecture Highlights

### Lexer (`src/lexer/`)
- **Token-based**: Converts jq query strings into token streams
- **60+ token types**: Numbers, strings, keywords, operators, punctuation
- **Error handling**: Precise error reporting with position tracking
- **Features**: String escapes, comments, multi-char operators (`..`, `==`, `!=`, etc.)

### Parser (`src/parser/`)
- **Recursive descent**: Precedence-climbing for expressions
- **Operator precedence**: Pipe → Comma → Assignment → Or → And → Comparison → Additive → Multiplicative → Unary → Postfix → Primary
- **AST generation**: Produces strongly-typed AST nodes
- **Error recovery**: Detailed error messages with context

### Interpreter (`src/interpreter/`)
- **Streaming semantics**: Returns `Iterator[Json]` for multiple results
- **Environment-based**: Variable bindings via immutable environment
- **Type coercion**: Arithmetic operations work across JSON types (e.g., string + string, array + array)
- **Lazy evaluation**: Efficient iteration without materializing intermediate results

## Implementation Notes

- **Standard library JSON**: Uses `Json` from `moonbitlang/core/json` (not custom types)
- **Pattern matching**: Comprehensive pattern matching on `Json` variants with `..` for `repr` field
- **Error propagation**: Checked errors via `raise` annotations
- **Functional style**: Immutable data structures, no side effects
- **Iterator-based**: `Iterator[T]` for jq's streaming semantics

## Building

```bash
# Build the project
moon build

# Check types
moon check

# Format code
moon fmt

# Generate documentation
moon info
```

## Completeness

This implementation covers the core jq functionality:
- ✅ All basic jq operators and expressions
- ✅ Array and object manipulation
- ✅ Control flow constructs
- ✅ Essential built-in functions
- ✅ Streaming/multiple results
- ❌ Not yet implemented: `reduce`, `as` patterns, string interpolation, advanced recursion, format strings, more built-ins

## License

See LICENSE file.
