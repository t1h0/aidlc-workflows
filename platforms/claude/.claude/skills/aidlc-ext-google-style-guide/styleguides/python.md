# Python Style Guide

Style rules for AI coding agents writing Python. Rules are imperative — apply them directly. Examples labeled `Yes:` are correct; examples labeled `No:` are violations to avoid.

## 1 Language Rules

### 1.1 Lint

Run `ruff check` over generated code. Fix all warnings, or suppress them only with a justification.

To suppress a warning on a specific line, use a `# noqa` comment with the rule code. Add an explanatory note when the rule code alone is not self-evident:

```python
def do_PUT(self):  # noqa: N802 - WSGI name
    ...
```

To suppress an unused-argument warning, prefix the parameter name with `_`. Keep the name descriptive:

```python
def viking_cafe_order(spam: str, _beans: str, _eggs: str | None = None) -> str:
    return spam + spam + spam
```

Do not delete arguments at the start of a function or assign them to `_` — those forms break keyword-argument callers and do not enforce non-use.

### 1.2 Imports

Use `import` statements for packages and modules only — never for individual types, classes, or functions (with the exemptions in 1.2.1).

- Use `import x` for packages and modules.
- Use `from x import y` where `x` is the package prefix and `y` is the module name.
- Use `from x import y as z` when:
  - Two modules named `y` would collide.
  - `y` collides with a top-level name in the current module.
  - `y` collides with a common public-API parameter name (e.g., `features`).
  - `y` is inconveniently long.
  - `y` is too generic in context (e.g., `from storage.file_system import options as fs_options`).
- Use `import y as z` only when `z` is a standard abbreviation (e.g., `import numpy as np`).

Example — importing `sound.effects.echo`:

```python
from sound.effects import echo
...
echo.EchoFilter(input, output, delay=0.7, atten=4)
```

Never use relative imports. Always use the full package name. `import jodie` refers to a third-party or top-level package — never assume the binary's directory is on `sys.path`.

#### 1.2.1 Exemptions

The following may be imported as individual symbols:

- Symbols from `typing`, `collections.abc`, and `typing_extensions` (used for static analysis).

### 1.3 Packages

Import each module by its full package path:

```python
# Yes (verbose form):
import absl.flags
from doctor.who import jodie

_FOO = absl.flags.DEFINE_string(...)
```

```python
# Yes (common form):
from absl import flags
from doctor.who import jodie

_FOO = flags.DEFINE_string(...)
```

```python
# No — ambiguous, depends on sys.path:
import jodie
```

### 1.4 Exceptions

- Raise built-in exceptions when applicable. Use `ValueError` for violated preconditions on function arguments.
- Do not use `assert` for control flow or precondition validation. `assert` may be stripped at runtime. The litmus test: if removing the `assert` would break the code, it is misused.
  - Inside `pytest`-based tests, `assert` is the expected mechanism for verifying expectations.

```python
# Yes:
def connect_to_next_port(self, minimum: int) -> int:
    """Connects to the next available port.

    Args:
        minimum: A port value greater or equal to 1024.

    Returns:
        The new minimum port.

    Raises:
        ConnectionError: If no available port is found.
    """
    if minimum < 1024:
        raise ValueError(f'Min. port must be at least 1024, not {minimum}.')
    port = self._find_next_open_port(minimum)
    if port is None:
        raise ConnectionError(
            f'Could not connect to service on port {minimum} or higher.')
    assert port >= minimum, (
        f'Unexpected port {port} when minimum was {minimum}.')
    return port
```

```python
# No — control flow depends on assert:
def connect_to_next_port(self, minimum: int) -> int:
    assert minimum >= 1024, 'Minimum port must be at least 1024.'
    port = self._find_next_open_port(minimum)
    assert port is not None
    return port
```

- Custom exceptions must inherit from an existing exception class. End names with `Error` and avoid repetition (`foo.FooError`).
- Never use bare `except:`, `except Exception:`, or `except StandardError:` except to:
  - Re-raise the exception, or
  - Create an isolation point that records and suppresses (e.g., a thread's outermost block).
- Minimize code inside `try` blocks. The larger the body, the more likely an unrelated line raises and hides a real error.
- Use `finally` for cleanup that must run regardless of whether an exception was raised.

### 1.5 Mutable Global State

Avoid mutable global state.

When unavoidable, declare such state at module level or as a class attribute, prefix it with `_` to mark it internal, and expose access through public functions or methods. Document the design rationale in a comment.

Module-level constants are permitted and encouraged. Use ALL_CAPS_WITH_UNDERSCORES:

```python
_MAX_HOLY_HANDGRENADE_COUNT = 3            # internal
SIR_LANCELOTS_FAVORITE_COLOR = "blue"      # public API
```

### 1.6 Nested/Local/Inner Classes and Functions

Use nested functions or classes only to close over a local value (other than `self` or `cls`). Do not nest a function purely to hide it; prefix the name with `_` at module level instead, so tests can still reach it. Inner classes are fine.

### 1.7 Comprehensions and Generator Expressions

Use comprehensions for simple cases. Multiple `for` clauses or filter expressions in a single comprehension are not permitted — fall back to a regular loop. Optimize for readability.

```python
# Yes:
result = [mapping_expr for value in iterable if filter_expr]

result = [
    is_valid(metric={'key': value})
    for value in interesting_iterable
    if a_longer_filter_expression(value)
]

return {
    x: complicated_transform(x)
    for x in long_generator_function(parameter)
    if x is not None
}

return (x**2 for x in range(10))

unique_names = {user.name for user in users if user is not None}

# Multiple loops require a regular for-loop:
result = []
for x in range(10):
    for y in range(5):
        if x * y > 10:
            result.append((x, y))
```

```python
# No — multiple for clauses in a comprehension:
result = [(x, y) for x in range(10) for y in range(5) if x * y > 10]

return (
    (x, y, z)
    for x in range(5)
    for y in range(5)
    if x != y
    for z in range(5)
    if y != z
)
```

### 1.8 Default Iterators and Operators

Use default iterators and `in`/`not in` membership operators. Do not mutate a container while iterating over it.

```python
# Yes:
for key in adict: ...
if obj in alist: ...
for line in afile: ...
for k, v in adict.items(): ...
```

```python
# No:
for key in adict.keys(): ...
for line in afile.readlines(): ...
```

### 1.9 Generators

Use `Yields:` instead of `Returns:` in the docstring of a generator function.

If a generator manages an expensive resource, force its cleanup by wrapping the generator with a context manager (see [PEP 533](https://peps.python.org/pep-0533/)).

### 1.10 Lambda Functions

Lambdas are allowed for one-liners. If the body spans multiple lines or exceeds 60–80 characters, use a nested function instead.

For common operations like multiplication, prefer the `operator` module (e.g., `operator.mul`) over `lambda x, y: x * y`.

### 1.11 Conditional Expressions

Allowed for simple cases. Each portion (true-expression, condition, else-expression) must fit on one line. Use a full `if` statement otherwise.

```python
# Yes:
one_line = 'yes' if predicate(value) else 'no'
slightly_split = ('yes' if predicate(value)
                  else 'no, nein, nyet')
the_longest_ternary_style_that_can_be_done = (
    'yes, true, affirmative, confirmed, correct'
    if predicate(value)
    else 'no, false, negative, nay')
```

```python
# No:
bad_line_breaking = ('yes' if predicate(value) else
                     'no')
portion_too_long = ('yes'
                    if some_long_module.some_long_predicate_function(
                        really_long_variable_name)
                    else 'no, false, negative, nay')
```

### 1.12 Default Argument Values

Allowed, with one rule: never use mutable objects as default values.

```python
# Yes:
def foo(a, b=None):
    if b is None:
        b = []

def foo(a, b: Sequence | None = None):
    if b is None:
        b = []

def foo(a, b: Sequence = ()):  # tuples are immutable.
    ...
```

```python
# No:
def foo(a, b=[]): ...
def foo(a, b=time.time()): ...        # evaluated at import
def foo(a, b=_FOO.value): ...         # flags not yet parsed
def foo(a, b: Mapping = {}): ...      # mutable default
```

### 1.13 Properties

Use `@property` to control attribute access only when there is meaningful computation or logic. Property access must be cheap, straightforward, and unsurprising.

- Do not use a property to merely get and set an internal attribute — make the attribute public.
- Use a property to control access or compute a *trivially* derived value.
- Always create properties with the `@property` decorator. Manual descriptor implementations are a [power feature](#118-power-features) — avoid them.
- Do not use properties for computations that a subclass may override.

### 1.14 True/False Evaluations

Prefer implicit truthiness checks (`if foo:`) over explicit comparisons (`if foo != []:`).

- For `None` checks, always use `is None` / `is not None`. Other values may also be falsy.
- Never compare a boolean to `False` with `==`. Use `if not x:`. To distinguish `False` from `None`, chain expressions: `if not x and x is not None:`.
- For sequences (str, list, tuple), use `if seq:` / `if not seq:` rather than `if len(seq):` / `if not len(seq):`.
- For integers, prefer explicit comparison to `0` to avoid conflating `None` and `0`. Do not apply this when the value is the result of `len()`.

```python
# Yes:
if not users:
    print('no users')

if i % 10 == 0:
    self.handle_multiple_of_ten()

def f(x=None):
    if x is None:
        x = []
```

```python
# No:
if len(users) == 0:
    print('no users')

if not i % 10:
    self.handle_multiple_of_ten()

def f(x=None):
    x = x or []
```

- `'0'` (the string) is truthy.
- NumPy arrays may raise in a boolean context. Use `.size` to test emptiness (e.g., `if not users.size`).

### 1.15 Lexical Scoping

Lexical scoping is allowed. A nested function may read names from enclosing scopes:

```python
def get_adder(summand1: float) -> Callable[[float], float]:
    """Returns a function that adds numbers to a given number."""
    def adder(summand2: float) -> float:
        return summand1 + summand2

    return adder
```

### 1.16 Function and Method Decorators

Use decorators only when there is a clear advantage. Decorator docstrings must clearly state the function is a decorator. Write unit tests for decorators.

Decorators run at import time. Avoid external dependencies inside the decorator (files, sockets, DB connections) — they may not be available at import. A decorator called with valid parameters should always succeed.

- Never use `staticmethod` unless required to integrate with an existing API. Use a module-level function instead.
- Use `classmethod` only for named constructors or for class-specific routines that modify class-wide state (e.g., a process-wide cache).

### 1.17 Threading

Do not rely on the atomicity of built-in types. Built-in dict operations may not be atomic when `__hash__` or `__eq__` are user-defined. Variable assignment is not guaranteed atomic either.

Use `queue.Queue` to communicate between threads. Otherwise use `threading` primitives — prefer `threading.Condition` (condition variables) over lower-level locks.

### 1.18 Power Features

Avoid power features: custom metaclasses, bytecode access, on-the-fly compilation, dynamic inheritance, object reparenting, import hacks, reflection (e.g., `getattr()` tricks), modification of system internals, custom `__del__` methods.

Standard library facilities that internally use these features are fine to use (e.g., `abc.ABCMeta`, `dataclasses`, `enum`).

### 1.19 Modern Python: `from __future__ import`

`from __future__` imports are encouraged. They enable features from later Python versions on a per-file basis. Keep them in place even when the feature is not currently used — removing them risks reintroducing legacy behavior on later edits.

For code that may run on Python ≤ 3.6, include:

```python
from __future__ import generator_stop
```

### 1.20 Type Annotated Code

- Annotate public APIs.
- Type-check at build time with [`ty`](https://github.com/astral-sh/ty).
- Annotate code that has been prone to type-related bugs.
- Annotate code that is hard to understand.
- Annotate stable code; this is usually safe without losing flexibility.

In most cases, put annotations in source files. For third-party or extension modules, put them in stub `.pyi` files (see [PEP 484](https://peps.python.org/pep-0484/#stub-files)).

Syntax:

```python
def func(a: int) -> list[int]: ...

a: SomeType = some_func()
```

If type analysis adoption is blocked by inferred-type issues, leave a TODO comment with a bug link.

## 2 Style Rules

### 2.1 Semicolons

Do not terminate lines with semicolons. Do not put two statements on the same line with a semicolon.

### 2.2 Line Length

Maximum line length is **80 characters**.

Explicit exceptions:

- Long import statements.
- URLs, pathnames, or long flags in comments.
- Long string module-level constants without splittable whitespace (e.g., URLs or pathnames).
- Ruff `noqa` comments (e.g., `# noqa: E501`).

Do not use a backslash for explicit line continuation. Use Python's implicit line joining inside parentheses, brackets, and braces. Add an extra pair of parentheses around an expression when needed. (Backslash-escaped newlines inside string literals are fine — see [2.10](#210-strings).)

```python
# Yes:
foo_bar(self, width, height, color='black', design=None, x='foo',
        emphasis=None, highlight=0)

if (width == 0 and height == 0 and
        color == 'red' and emphasis == 'strong'):
    ...

(bridge_questions.clarification_on
 .average_airspeed_of.unladen_swallow) = 'African or European?'

with (
    very_long_first_expression_function() as spam,
    very_long_second_expression_function() as beans,
    third_thing() as eggs,
):
    place_order(eggs, beans, spam, beans)
```

```python
# No:
if width == 0 and height == 0 and \
        color == 'red' and emphasis == 'strong':
    ...

bridge_questions.clarification_on \
    .average_airspeed_of.unladen_swallow = 'African or European?'

with very_long_first_expression_function() as spam, \
      very_long_second_expression_function() as beans, \
      third_thing() as eggs:
    place_order(eggs, beans, spam, beans)
```

When a literal string won't fit on a single line, use parentheses for implicit line joining:

```python
x = ('This will build a very long long '
     'long long long long long long string')
```

Break lines at the highest possible syntactic level. If breaking twice, break at the same syntactic level both times.

```python
# Yes:
bridgekeeper.answer(
    name="Arthur", quest=questlib.find(owner="Arthur", perilous=True))

answer = (a_long_line().of_chained_methods()
          .that_eventually_provides().an_answer())

if (
    config is None
    or 'editor.language' not in config
    or config['editor.language'].use_spaces is False
):
    use_tabs()
```

```python
# No:
bridgekeeper.answer(name="Arthur", quest=questlib.find(
    owner="Arthur", perilous=True))

answer = a_long_line().of_chained_methods().that_eventually_provides(
    ).an_answer()

if (config is None or 'editor.language' not in config or config[
    'editor.language'].use_spaces is False):
    use_tabs()
```

Within comments, put long URLs on their own line:

```python
# Yes:
# See details at
# http://www.example.com/us/developer/documentation/api/content/v2.0/csv_file_name_extension_full_specification.html
```

Docstring summary lines must stay within 80 characters.

If `ruff format` cannot bring a line within 80 characters, the line may exceed the limit. Manually break it where reasonable.

### 2.3 Parentheses

Use parentheses sparingly. Parentheses around tuples are fine but optional. Do not use them in `return` or conditional statements unless required for line continuation or to indicate a tuple.

```python
# Yes:
if foo:
    bar()
while x:
    x = bar()
if x and y:
    bar()
if not x:
    bar()
onesie = (foo,)              # 1-element tuple — parens visually clearer than the comma alone
return foo
return spam, beans
return (spam, beans)
for (x, y) in dict.items(): ...
```

```python
# No:
if (x):
    bar()
if not(x):
    bar()
return (foo)
```

### 2.4 Indentation

Indent with **4 spaces**. Never use tabs.

When wrapping, align with the opening delimiter or use a 4-space hanging indent. Closing brackets may go at the end of the expression or on their own line aligned with the opening line's indent.

```python
# Yes:

# Aligned with opening delimiter.
foo = long_function_name(var_one, var_two,
                         var_three, var_four)
meal = (spam,
        beans)

# Aligned with opening delimiter in a dictionary.
foo = {
    'long_dictionary_key': value1 +
                           value2,
    ...
}

# 4-space hanging indent; nothing on first line.
foo = long_function_name(
    var_one, var_two, var_three,
    var_four)
meal = (
    spam,
    beans)

# 4-space hanging indent; closing parenthesis on a new line.
foo = long_function_name(
    var_one, var_two, var_three,
    var_four
)
meal = (
    spam,
    beans,
)

# 4-space hanging indent in a dictionary.
foo = {
    'long_dictionary_key':
        long_dictionary_value,
    ...
}
```

```python
# No:

# Stuff on first line forbidden.
foo = long_function_name(var_one, var_two,
    var_three, var_four)
meal = (spam,
    beans)

# 2-space hanging indent forbidden.
foo = long_function_name(
  var_one, var_two, var_three,
  var_four)

# No hanging indent in a dictionary.
foo = {
    'long_dictionary_key':
    long_dictionary_value,
    ...
}
```

#### 2.4.1 Trailing Commas

Use a trailing comma only when the closing `]`, `)`, or `}` is on its own line, or for single-element tuples. The trailing comma signals `ruff format` to lay items out one per line.

```python
# Yes:
golomb3 = [0, 1, 3]
golomb4 = [
    0,
    1,
    4,
    6,
]
```

```python
# No:
golomb4 = [
    0,
    1,
    4,
    6,]
```

### 2.5 Blank Lines

- Two blank lines between top-level definitions (functions or classes).
- One blank line between method definitions and between a class docstring and its first method.
- No blank line directly after a `def` line.
- Use single blank lines inside functions or methods to separate logical sections as needed.

### 2.6 Whitespace

- No whitespace inside parentheses, brackets, or braces.
- No whitespace before commas, semicolons, or colons. One space after, except at end of line.
- No whitespace before the open paren/bracket of a call, indexing, or slicing.
- No trailing whitespace.

```python
# Yes:
spam(ham[1], {'eggs': 2}, [])

if x == 4:
    print(x, y)
x, y = y, x

spam(1)
dict['key'] = list[index]
```

```python
# No:
spam( ham[ 1 ], { 'eggs': 2 }, [ ] )
if x == 4 :
    print(x , y)
spam (1)
dict ['key'] = list [index]
```

Surround binary operators with single spaces for assignment (`=`), comparisons (`==, <, >, !=, <=, >=, in, not in, is, is not`), and booleans (`and, or, not`). Spaces around arithmetic operators (`+`, `-`, `*`, `/`, `//`, `%`, `**`, `@`) are at discretion — be consistent within a file.

```python
# Yes:
x == 1

# No:
x<1
```

Never use spaces around `=` in keyword arguments or default parameter values — except when a type annotation is present, then **do** use spaces.

```python
# Yes:
def complex(real, imag=0.0): return Magic(r=real, i=imag)
def complex(real, imag: float = 0.0): return Magic(r=real, i=imag)
```

```python
# No:
def complex(real, imag = 0.0): return Magic(r = real, i = imag)
def complex(real, imag: float=0.0): return Magic(r = real, i = imag)
```

Do not vertically align tokens (`:`, `#`, `=`) on consecutive lines:

```python
# Yes:
foo = 1000  # comment
long_name = 2  # comment that should not be aligned

dictionary = {
    'foo': 1,
    'long_name': 2,
}
```

```python
# No:
foo       = 1000  # comment
long_name = 2     # comment that should not be aligned

dictionary = {
    'foo'      : 1,
    'long_name': 2,
}
```

### 2.7 Shebang Line

Most `.py` files do not need a shebang. The main file of an executable program may start with:

```bash
#!/usr/bin/env python3
```

(or `#!/usr/bin/python3` per [PEP 394](https://peps.python.org/pep-0394/)). The shebang is only meaningful for files run directly.

### 2.8 Comments and Docstrings

#### 2.8.1 Docstrings

Use triple-double-quote `"""` format (per [PEP 257](https://peps.python.org/pep-0257/)). A docstring starts with a single summary line (≤ 80 chars) ending with `.`, `?`, or `!`. If more text follows, separate it with one blank line; subsequent lines start at the same column as the first quote of the first line.

#### 2.8.2 Module Docstrings

Every module starts with a docstring describing its contents and usage.

```python
"""A one-line summary of the module or program, terminated by a period.

Leave one blank line.  The rest of this docstring should contain an
overall description of the module or program.  Optionally, it may also
contain a brief description of exported classes and functions and/or usage
examples.

Typical usage example:

  foo = ClassFoo()
  bar = foo.function_bar()
"""
```

##### 2.8.2.1 Test Modules

Module-level docstrings for test files are optional. Add one only when there is information beyond the obvious — e.g., how to run the test, an unusual setup pattern, an external dependency.

```python
"""This blaze test uses golden files.

You can update those files by running
`blaze run //foo/bar:foo_test -- --update_golden_files` from the `google3`
directory.
"""
```

Do not add docstrings that contain no new information:

```python
"""Tests for foo.bar."""
```

#### 2.8.3 Function and Method Docstrings

A docstring is mandatory for every function (including methods, generators, and properties) that has any of the following:

- Part of the public API.
- Nontrivial size.
- Non-obvious logic.

A docstring should be enough to write a call to the function without reading its body. Document the calling syntax and semantics, not implementation details — unless those details affect callers (e.g., side effects on arguments).

Use either descriptive style (`"""Fetches rows from a Bigtable."""`) or imperative style (`"""Fetch rows from a Bigtable."""`) — be consistent within a file. Property docstrings should describe the value (`"""The Bigtable path."""`), not the action (`"""Returns the Bigtable path."""`).

Use these sections (each begins with a heading line ending in a colon; subsequent lines have a 2- or 4-space hanging indent — be consistent within a file):

- **Args:** List each parameter by name, followed by `:` and a description. Use a hanging indent for descriptions that wrap. Include the type if there is no corresponding type annotation. List `*foo` and `**bar` if used.
- **Returns:** (or **Yields:** for generators) Describe semantics, including type info not captured by annotations. Omit if the function returns `None`. May also be omitted when the docstring opens with `"""Returns ..."""` / `"""Yields ..."""` and that sentence fully describes the return value. For tuple returns, describe as a single tuple: `"Returns: A tuple (mat_a, mat_b), where mat_a is ..., and ..."`. For generators, document the value yielded by `next()`, not the generator object.
- **Raises:** List exceptions relevant to the interface. Do not document exceptions raised when the documented API contract is violated (that would make misuse part of the API).

```python
def fetch_smalltable_rows(
    table_handle: smalltable.Table,
    keys: Sequence[bytes | str],
    require_all_keys: bool = False,
) -> Mapping[bytes, tuple[str, ...]]:
    """Fetches rows from a Smalltable.

    Retrieves rows pertaining to the given keys from the Table instance
    represented by table_handle.  String keys will be UTF-8 encoded.

    Args:
        table_handle: An open smalltable.Table instance.
        keys: A sequence of strings representing the key of each table
          row to fetch.  String keys will be UTF-8 encoded.
        require_all_keys: If True only rows with values set for all keys will be
          returned.

    Returns:
        A dict mapping keys to the corresponding table row data
        fetched. Each row is represented as a tuple of strings. For
        example:

        {b'Serak': ('Rigel VII', 'Preparer'),
         b'Zim': ('Irk', 'Invader'),
         b'Lrrr': ('Omicron Persei 8', 'Emperor')}

        Returned keys are always bytes.  If a key from the keys argument is
        missing from the dictionary, then that row was not found in the
        table (and require_all_keys must have been False).

    Raises:
        IOError: An error occurred accessing the smalltable.
    """
```

The line-break variant of `Args:` is also allowed:

```python
def fetch_smalltable_rows(
    table_handle: smalltable.Table,
    keys: Sequence[bytes | str],
    require_all_keys: bool = False,
) -> Mapping[bytes, tuple[str, ...]]:
    """Fetches rows from a Smalltable.

    ...

    Args:
      table_handle:
        An open smalltable.Table instance.
      keys:
        A sequence of strings representing the key of each table row to
        fetch.  String keys will be UTF-8 encoded.
      require_all_keys:
        If True only rows with values set for all keys will be returned.

    Returns:
      ...
    """
```

##### 2.8.3.1 Overridden Methods

A method that overrides a base-class method does not need a docstring if it is decorated with [`@override`](https://typing-extensions.readthedocs.io/en/latest/#override) (from `typing_extensions` or `typing`). Add a docstring if the override materially refines the base method's contract or has additional details (e.g., new side effects).

```python
from typing_extensions import override

class Parent:
    def do_something(self):
        """Parent method, includes docstring."""

# Annotated with override → no docstring required.
class Child(Parent):
    @override
    def do_something(self):
        pass
```

```python
# No @override → docstring required.
class Child(Parent):
    def do_something(self):
        pass

# Trivial docstring on an override that just defers to the base class.
class Child(Parent):
    @override
    def do_something(self):
        """See base class."""
```

#### 2.8.4 Class Docstrings

Place a docstring directly below the class definition. Document public attributes (excluding properties) in an `Attributes:` section using the same format as `Args:`.

```python
class SampleClass:
    """Summary of class here.

    Longer class information...
    Longer class information...

    Attributes:
        likes_spam: A boolean indicating if we like SPAM or not.
        eggs: An integer count of the eggs we have laid.
    """

    def __init__(self, likes_spam: bool = False):
        """Initializes the instance based on spam preference.

        Args:
          likes_spam: Defines if instance exhibits this preference.
        """
        self.likes_spam = likes_spam
        self.eggs = 0

    @property
    def butter_sticks(self) -> int:
        """The number of butter sticks we have."""
```

The summary line must describe what an instance represents, not the fact that it is a class. For `Exception` subclasses, describe what the exception represents — not when it is raised.

```python
# Yes:
class CheeseShopAddress:
    """The address of a cheese shop.

    ...
    """

class OutOfCheeseError(Exception):
    """No more cheese is available."""
```

```python
# No:
class CheeseShopAddress:
    """Class that describes the address of a cheese shop.

    ...
    """

class OutOfCheeseError(Exception):
    """Raised when no more cheese is available."""
```

#### 2.8.5 Block and Inline Comments

Comment tricky parts of the code. Place a few-line comment block before complex operations; place short end-of-line comments on non-obvious individual statements.

```python
# We use a weighted dictionary search to find out where i is in
# the array.  We extrapolate position based on the largest num
# in the array and the array size and then do binary search to
# get the exact number.

if i & (i-1) == 0:  # True if i is 0 or a power of 2.
```

End-of-line comments must start at least 2 spaces from the code, then `#`, then at least one space, then text.

Do not narrate code:

```python
# Bad — describes what the code does, not why:
# Now go through the b array and make sure whenever i occurs
# the next element is i+1
```

#### 2.8.6 Punctuation, Spelling, and Grammar

Use proper punctuation, capitalization, and complete sentences in comments. Short end-of-line comments may be informal but should still be clear.

### 2.10 Strings

Use f-strings, the `%` operator, or `.format()`. A single `+` is fine for joining strings, but do not format with `+`.

```python
# Yes:
x = f'name: {name}; score: {n}'
x = '%s, %s!' % (imperative, expletive)
x = '{}, {}'.format(first, second)
x = 'name: %s; score: %d' % (name, n)
x = 'name: %(name)s; score: %(score)d' % {'name': name, 'score': n}
x = 'name: {}; score: {}'.format(name, n)
x = a + b
```

```python
# No:
x = first + ', ' + second
x = 'name: ' + name + '; score: ' + str(n)
```

Do not accumulate strings in a loop with `+` or `+=` — that can be O(n²). Append substrings to a list and join with `''.join(...)`, or write to an `io.StringIO`.

```python
# Yes:
items = ['<table>']
for last_name, first_name in employee_list:
    items.append('<tr><td>%s, %s</td></tr>' % (last_name, first_name))
items.append('</table>')
employee_table = ''.join(items)
```

```python
# No:
employee_table = '<table>'
for last_name, first_name in employee_list:
    employee_table += '<tr><td>%s, %s</td></tr>' % (last_name, first_name)
employee_table += '</table>'
```

Pick `'` or `"` for string quotes and use it consistently within a file. The other quote may be used to avoid backslash-escaping.

```python
# Yes:
Python('Why are you hiding your eyes?')
Gollum("I'm scared of lint errors.")
Narrator('"Good!" thought a happy Python reviewer.')
```

```python
# No (mixed for no reason):
Python("Why are you hiding your eyes?")
Gollum('The lint. It burns. It burns us.')
Gollum("Always the great lint. Watching. Watching.")
```

Use `"""` for multi-line strings rather than `'''`. (Files using `'` for regular strings may use `'''` for non-docstring multi-line strings.) Docstrings always use `"""`.

For multi-line strings that need clean indentation, use concatenated single-line strings or `textwrap.dedent()`:

```python
# No:
long_string = """This is pretty ugly.
Don't do this.
"""
```

```python
# Yes:
long_string = """This is fine if your use case can accept
    extraneous leading spaces."""

long_string = ("And this is fine if you cannot accept\n" +
               "extraneous leading spaces.")

long_string = ("And this too is fine if you cannot accept\n"
               "extraneous leading spaces.")

import textwrap

long_string = textwrap.dedent("""\
    This is also fine, because textwrap.dedent()
    will collapse common leading spaces in each line.""")
```

The backslash inside the string literal escapes a newline; it is not a line-continuation backslash and does not violate [2.2](#22-line-length).

#### 2.10.1 Logging

For logging functions that take a `%`-style pattern string as the first argument, always pass a string literal — never an f-string — and pass interpolated values as additional arguments. Logging frameworks may capture the unexpanded pattern as a queryable field, and deferred interpolation avoids work when the message is filtered.

```python
# Yes:
import tensorflow as tf
logger = tf.get_logger()
logger.info('TensorFlow Version is: %s', tf.__version__)

import os
from absl import logging

logging.info('Current $PAGER is: %s', os.getenv('PAGER', default=''))

homedir = os.getenv('HOME')
if homedir is None or not os.access(homedir, os.W_OK):
    logging.error('Cannot write to home directory, $HOME=%r', homedir)
```

```python
# No:
import os
from absl import logging

logging.info('Current $PAGER is:')
logging.info(os.getenv('PAGER', default=''))

homedir = os.getenv('HOME')
if homedir is None or not os.access(homedir, os.W_OK):
    logging.error(f'Cannot write to home directory, $HOME={homedir!r}')
```

#### 2.10.2 Error Messages

Error messages must:

1. Match the actual error condition precisely.
2. Make interpolated values clearly identifiable.
3. Be amenable to automated processing (greppable).

```python
# Yes:
if not 0 <= p <= 1:
    raise ValueError(f'Not a probability: {p=}')

try:
    os.rmdir(workdir)
except OSError as error:
    logging.warning('Could not remove directory (reason: %r): %r',
                    error, workdir)
```

```python
# No:
if p < 0 or p > 1:           # also false for float('nan')
    raise ValueError(f'Not a probability: {p=}')

try:
    os.rmdir(workdir)
except OSError:
    # Asserts a cause that may not be true.
    logging.warning('Directory already was deleted: %s', workdir)

try:
    os.rmdir(workdir)
except OSError:
    # Hard to grep; ambiguous when workdir == 'deleted':
    # "The deleted directory could not be deleted."
    logging.warning('The %s directory could not be deleted.', workdir)
```

### 2.11 Files, Sockets, and Stateful Resources

Explicitly close files, sockets, and similar resources (mmap mappings, h5py file objects, matplotlib figure windows, DB connections that wrap sockets, etc.).

Use the `with` statement:

```python
with open("hello.txt") as hello_file:
    for line in hello_file:
        print(line)
```

For file-like objects that don't support `with`, use `contextlib.closing()`:

```python
import contextlib

with contextlib.closing(urllib.urlopen("http://www.python.org/")) as front_page:
    for line in front_page:
        print(line)
```

Do not rely on `__del__` finalizers for cleanup with observable side effects — finalizer timing is not guaranteed across Python implementations, and stray references can extend object lifetime indefinitely.

If context-managed cleanup is infeasible, document resource lifetime management explicitly in the code.

### 2.12 TODO Comments

Use `TODO` for temporary code, short-term solutions, or "good enough but not perfect".

Format: `TODO: <link-to-resource> - <explanation>`. Prefer a tracked-bug link.

```python
# TODO: crbug.com/192795 - Investigate cpufreq optimizations.
```

Older formats are accepted in legacy code but not for new code:

```python
# TODO(crbug.com/192795): Investigate cpufreq optimizations.
# TODO(yourusername): ...
```

Do not use a person or team as the `TODO` context:

```python
# TODO: @yourusername - ...
```

If a TODO references a future date, give a specific date or event ("Remove this when all clients can handle XML responses.") — not a vague "later".

### 2.13 Imports Formatting

One import per line (with the [typing/collections.abc exception](#21912-imports-for-typing)).

```python
# Yes:
from collections.abc import Mapping, Sequence
import os
import sys
from typing import Any, NewType
```

```python
# No:
import os, sys
```

Place imports at the top of the file, after module docstrings and before module globals/constants. Group imports from most generic to least, with optional blank lines between groups:

1. `from __future__` imports.
2. Standard library imports.
3. Third-party imports.
4. Local repository / sub-package imports.

Within each group, sort lexicographically (case-insensitive) by full package path.

```python
import collections
import queue
import sys

from absl import app
from absl import flags
import bs4
import cryptography
import tensorflow as tf

from book.genres import scifi
from myproject.backend import huxley
from myproject.backend.hgwells import time_machine
from myproject.backend.state_machine import main_loop
from otherproject.ai import body
from otherproject.ai import mind
from otherproject.ai import soul
```

### 2.14 Statements

One statement per line.

A test-and-action may share one line only if the entire statement fits on it. This is forbidden for `try`/`except` (which spans multiple lines) and for `if` with an `else`.

```python
# Yes:
if foo: bar(foo)
```

```python
# No:
if foo: bar(foo)
else:   baz(foo)

try:               bar(foo)
except ValueError: baz(foo)

try:
    bar(foo)
except ValueError: baz(foo)
```

### 2.15 Getters and Setters

Use getter/setter functions only when getting or setting carries meaningful behavior — non-trivial computation, validation, or invalidation of state.

If a getter/setter pair just reads and writes an internal attribute, expose the attribute as public instead. If setting invalidates or rebuilds state, a setter function is appropriate (the function call hints at non-trivial work). [Properties](#113-properties) are also an option for simple logic.

Naming follows [2.16](#216-naming): `get_foo()` / `set_foo()`.

If a property previously controlled access to an attribute, do not paper over the change with new getter/setter functions that bind to the same property — let old access break visibly so callers see the new complexity.

### 2.16 Naming

Conventions:

| Entity                    | Convention                    |
| ------------------------- | ----------------------------- |
| Module                    | `module_name`                 |
| Package                   | `package_name`                |
| Class                     | `ClassName`                   |
| Method                    | `method_name`                 |
| Exception                 | `ExceptionName`               |
| Function                  | `function_name`               |
| Global/Class Constant     | `GLOBAL_CONSTANT_NAME`        |
| Global/Class Variable     | `global_var_name`             |
| Instance Variable         | `instance_var_name`           |
| Function/Method Parameter | `function_parameter_name`     |
| Local Variable            | `local_var_name`              |

Names must be descriptive. Avoid abbreviation — particularly ambiguous abbreviations and abbreviations that delete letters within a word.

Filenames always end in `.py` and never contain dashes.

#### 2.16.1 Names to Avoid

- Single-character names, except:
  - Counters or iterators (`i`, `j`, `k`, `v`, ...).
  - `e` for exceptions in `try/except`.
  - `f` for file handles in `with` statements.
  - Private type variables with no constraints (e.g., `_T = TypeVar("_T")`, `_P = ParamSpec("_P")`).
  - Names matching established notation in a referenced paper or algorithm (see [2.16.5](#2165-mathematical-notation)).

  Descriptiveness should scale with the name's scope. A short `i` is fine in a 5-line block; not in a multi-nested function.

- Dashes (`-`) in any package or module name.
- `__double_leading_and_trailing_underscore__` names (reserved by Python).
- Offensive terms.
- Names that include the variable's type (e.g., `id_to_name_dict`).

#### 2.16.2 Naming Conventions

- "Internal" means internal to a module, or protected/private within a class.
- Single underscore prefix (`_`) marks module-level variables and functions as protected. Linters flag protected access. Unit tests may access protected constants.
- Double underscore prefix (`__`) on instance variables/methods triggers name mangling (effectively private to the class). Avoid — it hurts readability and testability and is not actually private. Use a single underscore.
- Multiple related classes and top-level functions may live in the same module. There is no one-class-per-module rule.
- Use `CapWords` for class names; use `lower_with_under.py` for module names.
- New unit test files use PEP 8 method names (`test_<method_under_test>_<state>`). Legacy modules using CapWords function names may use mixed forms (`test<MethodUnderTest>_<state>`).

#### 2.16.3 File Naming

Filenames have a `.py` extension and no dashes. For an executable accessible without the extension, use a symlink or a bash wrapper containing `exec "$0.py" "$@"`.

#### 2.16.4 Naming Reference Table

| Type                       | Public               | Internal                          |
| -------------------------- | -------------------- | --------------------------------- |
| Packages                   | `lower_with_under`   |                                   |
| Modules                    | `lower_with_under`   | `_lower_with_under`               |
| Classes                    | `CapWords`           | `_CapWords`                       |
| Exceptions                 | `CapWords`           |                                   |
| Functions                  | `lower_with_under()` | `_lower_with_under()`             |
| Global/Class Constants     | `CAPS_WITH_UNDER`    | `_CAPS_WITH_UNDER`                |
| Global/Class Variables     | `lower_with_under`   | `_lower_with_under`               |
| Instance Variables         | `lower_with_under`   | `_lower_with_under` (protected)   |
| Method Names               | `lower_with_under()` | `_lower_with_under()` (protected) |
| Function/Method Parameters | `lower_with_under`   |                                   |
| Local Variables            | `lower_with_under`   |                                   |

#### 2.16.5 Mathematical Notation

For math-heavy code, short variable names are preferred when they match an established reference paper or algorithm. When using such names:

1. Cite the source (link to academic resource if possible) in a comment or docstring. If the source is inaccessible, document the convention explicitly.
2. Use PEP 8 `descriptive_names` for public APIs, which are likely to be read out of context.
3. Silence naming warnings narrowly: `# noqa: N802` per line, or a per-file override in `ruff.toml` for many cases.

### 2.17 Main

Modules must be importable (for `pydoc` and unit tests). For executables, put the main logic in a `main()` function and guard with `if __name__ == '__main__':`.

With absl:

```python
from absl import app
...

def main(argv: Sequence[str]):
    # process non-flag arguments
    ...

if __name__ == '__main__':
    app.run(main)
```

Without absl:

```python
def main():
    ...

if __name__ == '__main__':
    main()
```

Top-level code runs at import. Do not call functions, build objects, or otherwise side-effect at module top level if those should not occur at import (e.g., during `pydoc`).

### 2.18 Function Length

Prefer small, focused functions. There is no hard limit, but at ~40 lines, evaluate whether the function can be broken up without harming structure. Long functions tend to grow further over time and accumulate hard-to-find bugs.

### 2.19 Type Annotations

#### 2.19.1 General Rules

- Annotating `self` or `cls` is generally unnecessary. Use [`Self`](https://docs.python.org/3/library/typing.html#typing.Self) when needed:

```python
from typing import Self

class BaseClass:
    @classmethod
    def create(cls) -> Self:
        ...

    def difference(self, other: Self) -> float:
        ...
```

- Do not annotate `__init__`'s return value (it is always `None`).
- For values whose type cannot be expressed, use `Any`.
- Annotation is not required for every function, but at minimum:
  - Annotate public APIs.
  - Annotate code prone to type-related bugs.
  - Annotate code that is hard to understand.
  - Annotate stable code.

#### 2.19.2 Line Breaking

Follow [2.4](#24-indentation). When a signature wraps to multiple lines, put each parameter on its own line. A trailing comma after the last parameter ensures the return type also gets its own line.

```python
def my_method(
    self,
    first_var: int,
    second_var: Foo,
    third_var: Bar | None,
) -> int:
    ...
```

If everything fits on one line, keep it on one line:

```python
def my_method(self, first_var: int) -> int:
    ...
```

When the function name + last parameter + return type is too long, indent by 4 on a new line. Prefer one parameter per line and align the closing parenthesis with `def`:

```python
# Yes:
def my_method(
    self,
    other_arg: MyLongType | None,
) -> tuple[MyLongType1, MyLongType1]:
    ...
```

The return type may share a line with the last parameter:

```python
# Okay:
def my_method(
    self,
    first_var: int,
    second_var: int) -> dict[OtherLongType, MyLongType]:
    ...
```

Do not align the closing parenthesis with the opening one:

```python
# No:
def my_method(self,
              other_arg: MyLongType | None,
             ) -> dict[OtherLongType, MyLongType]:
    ...
```

Avoid breaking inside type expressions; keep sub-types intact when possible:

```python
def my_method(
    self,
    first_var: tuple[list[MyLongType1],
                     list[MyLongType2]],
    second_var: list[dict[
        MyLongType3, MyLongType4]],
) -> None:
    ...
```

If a single name + type is too long, prefer a [type alias](#2196-type-aliases). As a last resort, break after the colon and indent by 4:

```python
# Yes:
def my_function(
    long_variable_name:
        long_module_name.LongTypeName,
) -> None:
    ...
```

```python
# No:
def my_function(
    long_variable_name: long_module_name.
        LongTypeName,
) -> None:
    ...
```

#### 2.19.3 Forward Declarations

For a class name not yet defined (e.g., self-referential or referencing a class declared later), use `from __future__ import annotations` or quote the class name:

```python
# Yes:
from __future__ import annotations

class MyClass:
    def __init__(self, stack: Sequence[MyClass], item: OtherClass) -> None: ...

class OtherClass:
    ...
```

```python
# Yes:
class MyClass:
    def __init__(self, stack: Sequence['MyClass'], item: 'OtherClass') -> None: ...

class OtherClass:
    ...
```

#### 2.19.4 Default Values

Use spaces around `=` **only** when a parameter has both a type annotation and a default value (per [PEP 8](https://peps.python.org/pep-0008/#other-recommendations)).

```python
# Yes:
def func(a: int = 0) -> int: ...
```

```python
# No:
def func(a:int=0) -> int: ...
```

#### 2.19.5 NoneType

`None` is an alias for `NoneType`. If a value can be `None`, declare it. Use `X | None` (preferred in 3.10+) or `Optional`/`Union`.

Use explicit `X | None` rather than the implicit form. Earlier type checkers treated `a: str = None` as `a: str | None = None`; this is no longer accepted.

```python
# Yes:
def modern_or_union(a: str | int | None, b: str | None = None) -> str: ...
def union_optional(a: Union[str, int, None], b: Optional[str] = None) -> str: ...
```

```python
# No:
def nullable_union(a: Union[None, str]) -> str: ...
def implicit_optional(a: str = None) -> str: ...
```

#### 2.19.6 Type Aliases

Aliases of complex types use `CapWords`. Use a leading underscore for module-private aliases. The `: TypeAlias` annotation requires Python 3.10+.

```python
from typing import TypeAlias

_LossAndGradient: TypeAlias = tuple[tf.Tensor, tf.Tensor]
ComplexTFMap: TypeAlias = Mapping[str, _LossAndGradient]
```

#### 2.19.7 Ignoring Types

Disable type checking on a line with `# type: ignore`. For `ty`, scope the disable to a specific error code:

```python
# ty: ignore[attribute-access]
```

#### 2.19.8 Typing Variables

For internal variables whose type is hard or impossible to infer, use an annotated assignment:

```python
a: Foo = SomeUndecoratedFunction()
```

Do not use trailing `# type:` comments in new code:

```python
# Discouraged:
a = SomeUndecoratedFunction()  # type: Foo
```

#### 2.19.9 Tuples vs Lists

Typed lists hold a single type. Typed tuples may hold either a single repeated type or a fixed-length heterogeneous sequence (commonly used as a return type).

```python
a: list[int] = [1, 2, 3]
b: tuple[int, ...] = (1, 2, 3)
c: tuple[int, str, float] = (1, "2", 3.5)
```

#### 2.19.10 Type Variables

Use generics via `TypeVar` and `ParamSpec`:

```python
from collections.abc import Callable
from typing import ParamSpec, TypeVar

_P = ParamSpec("_P")
_T = TypeVar("_T")

def next(l: list[_T]) -> _T:
    return l.pop()

def print_when_called(f: Callable[_P, _T]) -> Callable[_P, _T]:
    def inner(*args: _P.args, **kwargs: _P.kwargs) -> _T:
        print("Function was called")
        return f(*args, **kwargs)
    return inner
```

Constrained `TypeVar`:

```python
AddableType = TypeVar("AddableType", int, float, str)
def add(a: AddableType, b: AddableType) -> AddableType:
    return a + b
```

`AnyStr` (from `typing`) is for cases where multiple annotations must all be `str` or all be `bytes`:

```python
from typing import AnyStr
def check_length(x: AnyStr) -> AnyStr:
    if len(x) <= 42:
        return x
    raise ValueError()
```

`TypeVar` names must be descriptive unless **both** are true: not externally visible, and not constrained.

```python
# Yes:
_T = TypeVar("_T")
_P = ParamSpec("_P")
AddableType = TypeVar("AddableType", int, float, str)
AnyFunction = TypeVar("AnyFunction", bound=Callable)
```

```python
# No:
T = TypeVar("T")                                # externally visible, single letter
P = ParamSpec("P")
_T = TypeVar("_T", int, float, str)             # constrained but not descriptive
_F = TypeVar("_F", bound=Callable)
```

#### 2.19.11 String Types

Do not use `typing.Text` in new code (it exists for Python 2/3 compatibility). Use `str` for text, `bytes` for binary data.

```python
def deals_with_text_data(x: str) -> str: ...
def deals_with_binary_data(x: bytes) -> bytes: ...
```

When all string types in a function must match (e.g., return type equals argument type), use [`AnyStr`](#21910-type-variables).

#### 2.19.12 Imports for Typing

For symbols from `typing` and `collections.abc`, import the symbol itself. Multiple symbols on one line are explicitly allowed for these modules:

```python
from collections.abc import Mapping, Sequence
from typing import Any, Generic, cast, TYPE_CHECKING
```

Treat names in `typing` and `collections.abc` like keywords — do not redefine them in your code. If a name collides, use `import x as y`:

```python
from typing import Any as AnyType
```

In function signatures, prefer abstract container types (`collections.abc.Sequence`) over concrete ones (`list`). When a concrete type is required (e.g., a typed `tuple`), prefer built-in types (`tuple`) over `typing` aliases (`typing.Tuple`).

```python
# No:
from typing import List, Tuple

def transform_coordinates(original: List[Tuple[float, float]]) -> \
    List[Tuple[float, float]]: ...
```

```python
# Yes:
from collections.abc import Sequence

def transform_coordinates(original: Sequence[tuple[float, float]]) -> \
    Sequence[tuple[float, float]]: ...
```

#### 2.19.13 Conditional Imports

Conditional imports are discouraged — refactor to allow top-level imports if possible. They are reserved for cases where a typing import must not happen at runtime.

Place type-only imports inside `if TYPE_CHECKING:` and reference the imported types as strings.

- Only declare type-only entities (including aliases) in this block; non-type uses cause runtime errors.
- Place the block right after the normal imports.
- No empty lines within the typing imports list.
- Sort the list as a regular import list.

```python
import typing
if typing.TYPE_CHECKING:
    import sketch
def f(x: "sketch.Sketch"): ...
```

#### 2.19.14 Circular Dependencies

Circular dependencies caused by typing are a code smell — refactor instead. When refactoring is impossible, replace the module-creating-the-cycle with `Any`. Use a meaningfully named alias and reference the real type name as a string. Separate the alias from the last import by one blank line.

```python
from typing import Any

some_mod = Any  # some_mod.py imports this module.
...

def my_method(self, var: "some_mod.SomeType") -> None: ...
```

#### 2.19.15 Generics

Always specify type parameters for generic types — unparameterized generics default to `Any`.

```python
# Yes:
def get_names(employee_ids: Sequence[int]) -> Mapping[int, str]: ...
```

```python
# No — Sequence and Mapping default to Any:
def get_names(employee_ids: Sequence) -> Mapping: ...
```

When `Any` is the right type parameter, write it explicitly — but `TypeVar` is often better:

```python
# No:
def get_names(employee_ids: Sequence[Any]) -> Mapping[Any, str]:
    """Returns a mapping from employee ID to employee name for given IDs."""
```

```python
# Yes:
_T = TypeVar('_T')
def get_names(employee_ids: Sequence[_T]) -> Mapping[_T, str]:
    """Returns a mapping from employee ID to employee name for given IDs."""
```

## 3 Local Consistency

When editing existing code, match local style for choices unspecified by these global rules (e.g., `_idx` suffix conventions). Local style applies only where these rules do not. Do not preserve old local style as a justification to skip a newer global rule.
