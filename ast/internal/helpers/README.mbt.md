# ast/internal/helpers

Internal helper functions for the jq interpreter. This package provides utility functions for JSON type inspection and truthiness evaluation.

## Overview

This is an internal package used by the `ast` interpreter. It contains helper functions that are shared across multiple interpreter modules. While technically public, this package is considered internal and its API may change without notice.

## Public Functions

### json_type_name

```moonbit nocheck
pub fn json_type_name(json : Json) -> String
```

Get the jq type name for a JSON value. This corresponds to what the jq `type` function returns.

**Parameters:**
- `json`: Any JSON value

**Returns:**
- A string representing the type: `"null"`, `"boolean"`, `"number"`, `"string"`, `"array"`, or `"object"`

**Example:**
```moonbit nocheck
json_type_name(Json::Null)           // "null"
json_type_name(Json::True)           // "boolean"
json_type_name(Json::False)          // "boolean"
json_type_name(Json::Number(42.0))   // "number"
json_type_name(Json::String("hi"))   // "string"
json_type_name(Json::Array([]))      // "array"
json_type_name(Json::Object({}))     // "object"
```

### is_truthy

```moonbit nocheck
pub fn is_truthy(value : Json) -> Bool
```

Determine if a JSON value is truthy according to jq semantics.

In jq, only `false` and `null` are falsy. Everything else (including `0`, `""`, `[]`, `{}`) is truthy.

**Parameters:**
- `value`: Any JSON value

**Returns:**
- `false` if the value is `null` or `false`
- `true` for all other values

**Example:**
```moonbit nocheck
is_truthy(Json::Null)           // false
is_truthy(Json::False)          // false
is_truthy(Json::True)           // true
is_truthy(Json::Number(0.0))    // true (unlike many languages!)
is_truthy(Json::String(""))     // true (unlike many languages!)
is_truthy(Json::Array([]))      // true
is_truthy(Json::Object({}))     // true
```

## Usage in Interpreter

These helpers are used throughout the interpreter for:

1. **Error messages**: `json_type_name` provides clear type names in `TypeMismatch` errors
2. **Conditional evaluation**: `is_truthy` determines which branch to take in `if-then-else`
3. **Logical operators**: `and`, `or`, and `not` use `is_truthy` for evaluation

## jq Truthiness Note

jq's truthiness differs from many programming languages:

| Value | jq | JavaScript | Python |
|-------|-----|------------|--------|
| `null` | falsy | falsy | falsy |
| `false` | falsy | falsy | falsy |
| `true` | truthy | truthy | truthy |
| `0` | **truthy** | falsy | falsy |
| `""` | **truthy** | falsy | falsy |
| `[]` | **truthy** | truthy | falsy |
| `{}` | **truthy** | truthy | falsy |

This design choice in jq means that only explicit `null` and `false` values are considered false, which simplifies many JSON processing patterns.
