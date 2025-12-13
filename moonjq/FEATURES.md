# MoonJQ Feature Status

## ✅ Implemented Features

### Core Operations
- ✅ Identity (`.`)
- ✅ Field access (`.foo`)
- ✅ Array indexing (`.[0]`, `.[-1]`)
- ✅ Array iteration (`.[]`)
- ✅ Array slicing (`.[2:4]`, `.[2:]`, `.[:4]`)
- ✅ Pipe operator (`|`)
- ✅ Comma operator (`,`)
- ✅ Optional operator (`?`)
- ✅ Recursive descent (`..`)

### Arithmetic & Logic
- ✅ Addition (`+`) - numbers, strings, arrays, objects
- ✅ Subtraction (`-`) - numbers, arrays
- ✅ Multiplication (`*`) - numbers, string repetition
- ✅ Division (`/`)
- ✅ Modulo (`%`)
- ✅ Comparison (`==`, `!=`, `<`, `<=`, `>`, `>=`)
- ✅ Logical operators (`and`, `or`, `not`)
- ✅ Alternative operator (`//`)

### Construction
- ✅ Array construction (`[expr]`, `[]`)
- ✅ Object construction (`{key: value}`, `{}`)

### Built-in Functions
- ✅ `length` - array/string/object length
- ✅ `keys` - object keys (preserves insertion order)
- ✅ `values` - object values
- ✅ `type` - get type name
- ✅ `empty` - produce no results
- ✅ `not` - boolean negation
- ✅ `map(expr)` - map over array
- ✅ `select(expr)` - filter elements
- ✅ `sort` - sort array
- ✅ `reverse` - reverse array
- ✅ `flatten` - flatten nested arrays
- ✅ `flatten(n)` - flatten to depth n
- ✅ `unique` - unique elements
- ✅ `add` - sum array elements
- ✅ `min` - minimum value
- ✅ `max` - maximum value
- ✅ `floor` - floor function
- ✅ `sqrt` - square root

### Control Flow
- ✅ `if-then-else-end`
- ✅ `try-catch`

### Advanced
- ✅ Variables (`$var`) - read only
- ✅ Streaming results (multiple outputs)
- ✅ Type coercion for arithmetic

## ❌ Missing Features (from plan.md)

### Critical Missing
- ❌ `as` patterns - `expr as $var | expr` (variable binding)
- ❌ `reduce` - `reduce expr as $var (init; update)`
- ❌ `sort_by(expr)` - sort by expression
- ❌ `group_by(expr)` - group by expression
- ❌ `recurse(f; cond)` - recursive with function and condition

### Assignment Operators
- ❌ Update operator (`|=`) - `.foo |= . + 1`
- ❌ Assignment operator (`=`) - `.foo = 42`

### Additional Built-ins (common in jq)
- ❌ `contains(value)` - check if contains
- ❌ `inside(value)` - inverse of contains
- ❌ `startswith(str)` - string prefix
- ❌ `endswith(str)` - string suffix
- ❌ `split(sep)` - split string
- ❌ `join(sep)` - join array
- ❌ `has(key)` - check key existence
- ❌ `in(object)` - check if key in object
- ❌ `to_entries` - convert object to key-value pairs
- ❌ `from_entries` - convert key-value pairs to object
- ❌ `with_entries(expr)` - transform entries
- ❌ `paths` - all paths in structure
- ❌ `leaf_paths` - paths to leaf values
- ❌ `any` - test if any element matches
- ❌ `all` - test if all elements match
- ❌ `range(n)` - generate range
- ❌ `until(cond; update)` - loop until condition
- ❌ `while(cond; update)` - loop while condition
- ❌ `limit(n; expr)` - limit results
- ❌ `first`, `last` - first/last element
- ❌ `nth(n)` - nth element
- ❌ `indices(value)` - find indices
- ❌ `index(value)` - find first index
- ❌ `rindex(value)` - find last index

### String Operations
- ❌ String interpolation (`\(expr)`)
- ❌ `ascii_downcase`, `ascii_upcase` - case conversion
- ❌ `ltrimstr(str)`, `rtrimstr(str)` - trim prefix/suffix
- ❌ `test(regex)` - regex match
- ❌ `match(regex)` - regex match with groups
- ❌ `capture(regex)` - capture groups
- ❌ `splits(regex)` - split by regex
- ❌ `sub(regex; replacement)` - replace first
- ❌ `gsub(regex; replacement)` - replace all

### Numeric Operations
- ❌ `round` - round to nearest integer
- ❌ `ceil` - ceiling function
- ❌ `abs` - absolute value
- ❌ `pow(exp)` - power function
- ❌ `log`, `log10`, `log2` - logarithms
- ❌ `exp`, `exp10`, `exp2` - exponentials
- ❌ `sin`, `cos`, `tan` - trigonometric
- ❌ `asin`, `acos`, `atan` - inverse trig
- ❌ `sinh`, `cosh`, `tanh` - hyperbolic

### Advanced Features
- ❌ Format strings (`@csv`, `@json`, `@base64`, etc.)
- ❌ User-defined functions (`def name(args): body;`)
- ❌ Scoped operators (`.foo += 1`)
- ❌ Path expressions (`path(expr)`)
- ❌ `getpath(path)`, `setpath(path; value)`, `delpaths(paths)`
- ❌ Comments in queries
- ❌ `$ENV` - environment variables
- ❌ `$__loc__` - location info

### Date/Time (low priority)
- ❌ `now` - current timestamp
- ❌ `fromdateiso8601`, `todateiso8601`
- ❌ `fromdate`, `todate`
- ❌ `strftime`, `strptime`

## Test Coverage

- ✅ 136 tests passing
  - 7 JSON tests
  - 31 Lexer tests
  - 52 Parser tests
  - 25 Interpreter tests
  - 21 Integration tests

## Priority for Next Implementation

### High Priority (Essential for practical use)
1. **`as` patterns** - Variable binding in pipelines
2. **`reduce`** - Powerful aggregation primitive
3. **`sort_by(expr)`** - Sort by custom expression
4. **`group_by(expr)`** - Group elements by expression
5. **Update operators** (`|=`, `+=`, etc.) - Modify in place
6. **`has(key)`** - Check key existence
7. **`to_entries` / `from_entries`** - Object transformation
8. **`any` / `all`** - Predicates on collections

### Medium Priority (Commonly used)
1. **String operations** - `split`, `join`, `startswith`, `endswith`
2. **`contains` / `inside`** - Containment checks
3. **`range(n)`** - Generate sequences
4. **`first` / `last` / `nth(n)`** - Element selection
5. **`paths` / `leaf_paths`** - Path enumeration
6. **`limit(n; expr)`** - Limit results
7. **`until` / `while`** - Loops
8. **`indices` / `index` / `rindex`** - Search operations

### Low Priority (Nice to have)
1. **Regex operations** - `test`, `match`, `capture`, `sub`, `gsub`
2. **Additional math functions** - `round`, `ceil`, `abs`, `pow`
3. **String case conversion** - `ascii_upcase`, `ascii_downcase`
4. **Format strings** - `@csv`, `@base64`, etc.
5. **User-defined functions** - `def` keyword
6. **Path manipulation** - `getpath`, `setpath`, `delpaths`

## Notes

The current implementation covers the essential core of jq and is sufficient for:
- Basic JSON querying and transformation
- Array and object manipulation
- Filtering and mapping
- Arithmetic and comparisons
- Control flow

To reach feature parity with jq core, focus on implementing the High Priority items first.
