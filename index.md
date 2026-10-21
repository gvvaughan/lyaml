---
layout: default
---
# LYAML

[LYAML] binds [LibYAML] to [LuaJIT] and [Lua] 5.1 through 5.5, for
reading and writing [YAML 1.1][yaml11]:

 * [`lyaml.load`](#2-loading) turns a YAML stream into Lua tables, and
   [`lyaml.dump`](#3-dumping) turns Lua tables back into YAML
 * [`lyaml.null`](#4-null) keeps YAML's nulls, which Lua tables can't
   hold as `nil`
 * the [scalar conversions](#5-scalar-conversions) of numbers, booleans
   and the rest are yours to change
 * a [low-level API](#6-the-low-level-api) of LibYAML's scanner, parser
   and emitter, for when the tables are not enough

The [API reference](api/) has every function in detail.


## 1. Installation

Install the latest release with [LuaRocks]:

{% highlight bash %}
    luarocks install lyaml
{% endhighlight %}

LYAML needs LibYAML and its headers, which most systems package as
`libyaml-dev` or `libyaml`.  If LuaRocks can't find them, say where
they are:

{% highlight bash %}
    luarocks install lyaml YAML_DIR=/opt/homebrew
{% endhighlight %}

Without LuaRocks, build and install it with [Luke], from a clone of the
[repository][lyaml]:

{% highlight bash %}
    build-aux/luke YAML_DIR=/opt/homebrew
    sudo build-aux/luke PREFIX=/usr/local install
{% endhighlight %}


## 2. Loading

`lyaml.load` returns the first document of a YAML stream as a Lua
value:

{% highlight lua %}
    local lyaml = require 'lyaml'

    lyaml.load 'foo: bar'
    --> {foo = 'bar'}
{% endhighlight %}

A mapping becomes a table with those keys, and a sequence a list.  With
`all = true` in its second argument, `load` returns a list of every
document in the stream instead:

{% highlight lua %}
    local stream = [[
    --- one
    ...
    --- two
    ...
    ]]

    lyaml.load(stream)                 --> 'one'
    lyaml.load(stream, {all = true})   --> {'one', 'two'}
{% endhighlight %}

An alias loads as the table its anchor names, so after

{% highlight lua %}
    local t = lyaml.load 'base: &b {x: 1}\nother: *b'
{% endhighlight %}

`t.base == t.other`.  Anchors are local to the document they are in.

`load` raises an error for a stream that LibYAML can't parse, or a
value that does not suit its tag, with the line and column where it
found the problem:

{% highlight lua %}
    lyaml.load 'a: !!int nope'
    --> error: 1:4: invalid 'tag:yaml.org,2002:int' value: 'nope'
{% endhighlight %}


## 3. Dumping

`lyaml.dump` takes a list of documents, and returns a YAML stream with
each of them in turn.  To dump one table, put it in a list of its own:

{% highlight lua %}
    lyaml.dump { {foo = 'bar'} }
    --> ---
    --> foo: bar
    --> ...

    lyaml.dump {'one', 'two'}
    --> --- one
    --> ...
    --> --- two
    --> ...
{% endhighlight %}

A table whose keys are exactly 1, 2, 3 and so on is dumped as a
sequence, and any other table as a mapping, in the order that `pairs`
returns its keys.  A string with a newline is dumped as a literal
block, and a string that would load as something else, such as `'42'`
or `'yes'`, is quoted, so that it loads as a string again.  `dump`
raises an error for a function, userdata or thread.

The `anchors` field of the second argument maps anchor names to tables
that the documents contain.  `dump` writes such a table with its
anchor the first time it reaches it, and as an alias after that:

{% highlight lua %}
    local base = {x = 1}
    lyaml.dump({ {a = base, b = base} }, {anchors = {base = base}})
    --> ---
    --> a: &base
    -->   x: 1
    --> b: *base
    --> ...
{% endhighlight %}


## 4. Null

A Lua table can't hold a key whose value is `nil`, but a YAML mapping
can have a key whose value is null.  So `load` returns YAML's null,
written `~`, `null` or nothing at all, as `lyaml.null`, and `dump`
writes `lyaml.null` as `~`:

{% highlight lua %}
    local t = lyaml.load 'a: ~'
    t.a == lyaml.null    --> true

    lyaml.dump {t}
    --> ---
    --> a: ~
    --> ...
{% endhighlight %}

`lyaml.null` is a value to compare with, not a function to call.


## 5. Scalar Conversions

A plain scalar, without quotes or a tag, is converted by the content
it has: `1` loads as a number, `yes` as `true`, `~` as `lyaml.null`,
and so on.  The functions in `lyaml.implicit` each try one conversion,
and return `nil` for a value they don't recognise:

| Function       | Recognises                                  |
|----------------|---------------------------------------------|
| `null`         | `~`, `null`, `Null`, `NULL` and nothing     |
| `bool`         | `true`/`false`, `yes`/`no` and `on`/`off`, in lower, capitalised or upper case |
| `octal`        | `012`                                       |
| `decimal`      | `12345`                                     |
| `float`        | `1e-3`, `-0.12`                             |
| `inf`, `nan`   | `.inf`, `-.inf`, `.nan`                     |
| `hexadecimal`  | `0xdeadbeef`                                |
| `binary`       | `0b1010_0111`                               |
| `sexagesimal`  | `190:20:30`                                 |
| `sexfloat`     | `190:20:30.15`                              |

By default, `load` tries them all, and leaves the value as a string if
none of them recognises it.  Pass your own function in the
`implicit_scalar` field of the second argument to choose differently,
such as with `anyof` from `lyaml.functional`, which tries each function
in turn and returns the first result that is not `nil`:

{% highlight lua %}
    local functional = require 'lyaml.functional'
    local implicit = require 'lyaml.implicit'

    -- Only nulls and decimals; yes, 0x1f and the rest stay strings.
    local strict = functional.anyof {
       implicit.null,
       implicit.decimal,
       functional.id,
    }

    lyaml.load('a: yes\nb: 10', {implicit_scalar = strict})
    --> {a = 'yes', b = 10}
{% endhighlight %}

Pass the same function to `dump` too, so that it quotes only the strings
that function would convert when they are loaded again.

A scalar with a tag is converted by the function for that tag in the
`explicit_scalar` field instead, a table keyed by the full tag name.
The default has the functions from `lyaml.explicit` for
`tag:yaml.org,2002:bool`, `float`, `int`, `null` and `str`, which
raise an error for a value that does not suit the tag.


## 6. The Low-Level API

The `yaml` module is the C binding to LibYAML that `lyaml` is built on.
`yaml.parser` returns an iterator over the events of a YAML stream,
each a table with a `type`, the `start_mark` and `end_mark` of where it
is in the stream, and the other fields of that event, such as the
`value`, `anchor`, `tag` and `style` of a scalar:

{% highlight lua %}
    local yaml = require 'yaml'

    for event in yaml.parser 'a: [1, b]' do
       print(event.type)
    end
    --> STREAM_START, DOCUMENT_START, MAPPING_START, SCALAR,
    --> SEQUENCE_START, SCALAR, SCALAR, SEQUENCE_END, MAPPING_END,
    --> DOCUMENT_END, STREAM_END
{% endhighlight %}

That is the "parse" step of the "parse, compose, construct" model of
the [YAML 1.1 specification][yaml11], with every detail of the stream
that `load` leaves out, such as line and column numbers.  `yaml.scanner`
returns an iterator over the tokens of the stream instead, one step
lower: see LibYAML's [yaml.h] for what each one holds.

`yaml.emitter` goes the other way.  Its `emit` function takes one event
table at a time, and the `STREAM_END` event returns `true` and the
stream:

{% highlight lua %}
    local emitter = yaml.emitter()
    emitter.emit {type = 'STREAM_START'}
    emitter.emit {type = 'DOCUMENT_START'}
    emitter.emit {type = 'SCALAR', value = 'hi'}
    emitter.emit {type = 'DOCUMENT_END'}
    local ok, stream = emitter.emit {type = 'STREAM_END'}
    --> stream == '--- hi\n...\n'
{% endhighlight %}


## 7. Bugs and Contributions

Please report bugs and make suggestions as [GitHub issues][issues], and
check that they are not already fixed on [master][lyaml] first.  Pull
requests are especially welcome.


[issues]:  https://github.com/gvvaughan/lyaml/issues
[libyaml]: https://pyyaml.org/wiki/LibYAML
[lua]:     https://www.lua.org
[luajit]:  https://luajit.org
[luarocks]: https://luarocks.org
[luke]:    https://github.com/gvvaughan/luke
[lyaml]:   https://github.com/gvvaughan/lyaml
[yaml.h]:  https://github.com/yaml/libyaml/blob/master/include/yaml.h
[yaml11]:  https://yaml.org/spec/1.1/
