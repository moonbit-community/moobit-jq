# MoonJQ — jq in MoonBit

MoonJQ is a jq-compatible JSON query interpreter written in MoonBit: lexer → parser → streaming interpreter (`Iterator[Json]`).

## Features (high level)

- jq core: `.`, field/index access, pipes, comma
- Operators: arithmetic, comparison, `and/or/not`
- Control flow: `if … then … else … end`, `try … catch …`
- jq extras: `?`, `//`, recursive descent `..`
- Built-ins: `map`, `select`, `keys`, `values`, `length`, `type`, `sort`, `reverse`, `flatten`, `unique`, `add`, `min`, `max`, …

## Project layout

```
.
├── moon.mod.json
├── ast/          # AST nodes (Expr, operators, literals)
├── lexer/        # tokenization
├── parser/       # recursive-descent parser
├── interpreter/  # evaluator (streaming semantics)
├── json/         # thin wrapper around stdlib Json
└── integration/  # end-to-end tests
```

## Real-world examples (doc-checked)

Run `moon check README.mbt.md` to type-check the snippets below.

```mbt check
///|
/// Evaluate a jq query and return newline-separated results (like jq).
fn jq(query : String, input : String) -> String raise {
  let expr = @parser.parse(query)
  let json = @moonjq_json.parse(input)
  @interpreter.eval(expr, json)
  .collect()
  .map(fn(v) { v.to_string() })
  .join("\n")
}

///|
test "readme: filter and project" {
  let query = ".users[] | select(.age >= 18) | {name: .name, email: .email}"
  let input =
    #|{
    #|  "users": [
    #|    { "name": "Alice", "age": 25, "email": "alice@example.com" },
    #|    { "name": "Bob", "age": 17, "email": "bob@example.com" }
    #|  ]
    #|}
  inspect(
    jq(query, input),
    content=(
      #|Object({"name": String("Alice"), "email": String("alice@example.com")})
    ),
  )
}

///|
test "readme: defaulting and optional" {
  let query =
    #|.user.name? // "(unknown)"#|
  let input =
    #|{
    #|  "user": {}
    #|}
  inspect(
    jq(query, input),
    content=(
      #|String("(unknown)")
    ),
  )
}

///|
test "readme: aggregate numbers" {
  let query = ".numbers | map(. * 2) | add"
  let input =
    #|{ "numbers": [1, 2, 3] }
  inspect(jq(query, input), content="Number(12)")
}

///|
test "readme: extract error messages" {
  let query =
    #|.events[] | select(.level == "error") | .message#|
  let input =
    #|{
    #|  "events": [
    #|    { "level": "info", "message": "startup" },
    #|    { "level": "error", "message": "disk full" },
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
moon check --package-path interpreter

# Run tests
moon test -p ast -p json -p lexer -p parser -p interpreter -p integration

# Update snapshots (expect tests)
moon test -p ast -p json -p lexer -p parser -p interpreter -p integration --update

# Generate/update public interfaces (.mbti)
moon info
```

## License

See `LICENSE`.
