<img src="assets/smuggler.jpg?raw=true" height="170" width="170" align="right">

# ConfigSmuggler [![Build Status](https://travis-ci.org/appcues/config_smuggler.svg?branch=master)](https://travis-ci.org/appcues/config_smuggler) [![Docs](https://img.shields.io/badge/api-docs-green.svg?style=flat)](https://hexdocs.pm/config_smuggler/config_smuggler.html) [![Hex.pm Version](http://img.shields.io/hexpm/v/config_smuggler.svg?style=flat)](https://hex.pm/packages/config_smuggler)

ConfigSmuggler is a library for converting Elixir-style configuration
statements to and from string-encoded key/value pairs.

Elixir (and Erlang)'s configuration system is somewhat richer than
naïve environment variables, i.e., `System.get_env/1`-style key/value
configs alone can capture.

Configs in Elixir are namespaced by app, can be arbitrarily nested, and
contain Elixir-native data types like atoms, keyword lists, etc.

ConfigSmuggler provides a bridge between Elixir applications and
key/value configuration stores, especially those available at runtime.
It makes it dead-simple to use platform-agnostic configuration
systems with Elixir services.

## WARNING!

The functions in `ConfigSmuggler` are *not suitable* for use on
untrusted inputs!  Code is `eval`ed, atoms are created, etc.

Configs are considered privileged inputs, so don't worry about using
ConfigSmuggler for its intended purpose.  But please, *never* let user
input anywhere near this module.  You've been warned.

## Example

```elixir
iex> encoded_configs = %{
...>   # imagine you fetch this every 60 seconds at runtime
...>   "elixir-logger-level" => ":debug",
...>   "elixir-my_api-MyApi.Endpoint-url-port" => "8888",
...> }
iex> ConfigSmuggler.apply(encoded_configs)
iex> Application.get_env(:logger, :level)
:debug
iex> ConfigSmuggler.encode([my_api: Application.get_all_env(:my_api)])
{:ok, %{"elixir-my_api-MyApi.Endpoint-url-port" => "8888"}}
```

## Installation

Add `:config_smuggler` to your list of deps in `mix.exs`:

```elixir
def deps do
  [
    {:config_smuggler, "~> 0.6.0"}
  ]
end
```

## Documentation

[Full documentation and usage examples can be found on
hexdocs.pm](https://hexdocs.pm/config_smuggler/ConfigSmuggler.html).

## Overview

* `apply/1` applies encoded or decoded configs to the current environment.

* `decode/1` converts an encoded config map into Elixir-native decoded
  configs, also returning a list of zero or more encoded key/value pairs
  that could not be decoded.

* `encode/1` converts Elixir-native decoded configs
  (i.e., a keyword list with app name as key and keyword list of
  configs as value) into an encoded config map.

* `encode_file/1` converts an entire `config.exs`-style file
  (along with all files included with `Mix.Config.import_config/1`)
  into an encoded config map.

* `encode_statement/1` converts a single `config` statement from a
  `config.exs`-style file into an encoded config map.

## Encoding Scheme

The encoded key begins with `elixir` and is a hyphen-separated "path"
of atoms and modules leading to the config value we wish to set.

The value is any valid Elixir term, encoded using normal Elixir syntax.

Encoding is performed by `Kernel.inspect/2`.
Decoding is performed by `Code.eval_string/1` and `String.to_atom/1`.

## Authorship and License

Copyright 2019, Appcues, Inc.

ConfigSmuggler is released under the [MIT License](MIT_LICENSE.txt).
