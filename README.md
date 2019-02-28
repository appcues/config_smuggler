<img src="assets/smuggler.jpg?raw=true" height="170" width="170" align="right">

# ConfigSmuggler [![Build Status](https://travis-ci.org/appcues/config_smuggler.svg?branch=master)](https://travis-ci.org/appcues/config_smuggler) [![Docs](https://img.shields.io/badge/api-docs-green.svg?style=flat)](https://hexdocs.pm/config_smuggler/config_smuggler.html) [![Hex.pm Version](http://img.shields.io/hexpm/v/config_smuggler.svg?style=flat)](https://hex.pm/packages/config_smuggler)

ConfigSmuggler is a library for converting Elixir-style configuration
statements to and from string-encoded key/value pairs.

Elixir (and Erlang)'s configuration system is somewhat richer than
naive `ENV`-style key/value configs alone can capture.  Configs in
Elixir are namespaced by app, can be arbitrarily nested, and can
contain Elixir-native data types like atoms, keyword lists, etc.

ConfigSmuggler provides a bridge between key/value configuration stores
and Elixir applications.  It's designed to make it easier to use
platform-agnostic configuration systems with Elixir services.

## WARNING!

The functions in `ConfigSmuggler` are *not suitable* for use on
untrusted inputs!  Code is `eval`ed, atoms are created, etc.
*Do not* pass user input to this module.

## Installation

Add `:config_smuggler` to your list of deps in `mix.exs`:

```elixir
def deps do
  [
    {:config_smuggler, "~> 0.5.0"}
  ]
end
```

## Usage

* `encode_file/1` converts an entire `config.exs`-style file
  (along with all files included with `import_config/1`) into
  an encoded config map.

* `encode_statement/1` converts a single `config` statement from a
  `config.exs`-style file into an encoded config map.

* `encode_env/1` converts Elixir-native decoded configs
  (i.e., a keyword list with app name as key and keyword list of
  configs as value) into an encoded config map.

* `decode/1` converts an encoded config map into Elixir-native decoded
  configs, also returning a list of zero or more encoded key/value pairs
  that could not be decoded.

## Documentation

[Documentation and usage examples can be found on
hexdocs.pm](https://hexdocs.pm/config_smuggler/ConfigSmuggler.html).

## Authorship and License

Copyright 2019, Appcues, Inc.

ConfigSmuggler is released under the [MIT License](MIT_LICENSE.txt).
