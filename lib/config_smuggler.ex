defmodule ConfigSmuggler do
  @moduledoc """
  <img src="https://github.com/appcues/config_smuggler/raw/master/assets/smuggler.jpg?raw=true" height="170" width="170" align="right">

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

  ## See Also

  If you build and deploy Erlang releases, and you want to apply encoded
  configs before any other apps have started, look into [Distillery
  config providers](https://hexdocs.pm/distillery/config/runtime.html#config-providers).

  This feature allows specified modules to make environment changes
  with `Application.put_env/3`, after which these changes are persisted to
  the release's `sys.config` file and the release is started normally.

  ## Gotchas

  Atoms and modules are expected to follow standard Elixir convention,
  namely that atoms begin with a lowercase letter, modules begin with
  an uppercase letter, and neither contains any hyphen characters.

  If a config file or statement makes reference to `Mix.env()`, the current
  Mix env will be substituted.  This may be different than what the config
  file intended.

  ## Authorship and License

  Copyright 2019, [Appcues, Inc.](https://www.appcues.com)

  ConfigSmuggler is released under the [MIT
  License](https://github.com/appcues/config_smuggler/blob/master/MIT_LICENSE.txt).
  """

  alias ConfigSmuggler.Apply
  alias ConfigSmuggler.Decoder
  alias ConfigSmuggler.Encoder

  @type encoded_key :: String.t()
  @type encoded_value :: String.t()
  @type encoded_config_map :: %{encoded_key => encoded_value}
  @type decoded_configs :: [{atom, Keyword.t()}]
  @type validation_error :: {{encoded_key, encoded_value}, error_reason}
  @type error_reason ::
          :bad_input
          | :bad_key
          | :bad_value
          | :load_error

  @doc ~S"""
  Applies the given config to the current environment (i.e., calls
  `Application.put_env/3` a bunch of times).  Accepts Elixir-
  native decoded configs or encoded config maps.

      iex> ConfigSmuggler.apply([my_app: [foo: 22]])
      iex> Application.get_env(:my_app, :foo)
      22

      iex> ConfigSmuggler.apply(%{"elixir-my_app-bar" => "33"})
      iex> Application.get_env(:my_app, :bar)
      33
  """
  @spec apply(decoded_configs | encoded_config_map) ::
          :ok | {:error, error_reason}
  def apply(config) when is_list(config), do: Apply.apply_decoded(config)
  def apply(%{} = config), do: Apply.apply_encoded(config)
  def apply(_), do: {:error, :bad_input}

  @doc ~S"""
  Decodes a map of string-encoded key/value pairs into a keyword list of
  Elixir configs, keyed by app.  Also returns a list of zero or more invalid
  key/value pairs along with their errors.

      iex> ConfigSmuggler.decode(%{
      ...>   "elixir-my_app-some_key" => "22",
      ...>   "elixir-my_app-MyApp.Endpoint-url-host" => "\"localhost\"",
      ...>   "elixir-logger-level" => ":info",
      ...>   "elixir-my_app-MyApp.Endpoint-url-port" => "4444",
      ...>   "bad key" => "22",
      ...>   "elixir-my_app-foo" => "bogus value",
      ...> })
      {:ok,
        [
          my_app: [
            {:some_key, 22},
            {MyApp.Endpoint, [
              url: [
                port: 4444,
                host: "localhost",
              ]
            ]},
          ],
          logger: [
            level: :info,
          ],
        ],
        [
          {{"elixir-my_app-foo", "bogus value"}, :bad_value},
          {{"bad key", "22"}, :bad_key},
        ]
      }
  """
  @spec decode(encoded_config_map) :: {:ok, decoded_configs, [validation_error]}
  def decode(encoded_config_map) do
    Decoder.decode_and_merge(encoded_config_map)
  end

  @doc ~S"""
  Converts Elixir-native decoded configs (i.e., a keyword list with
  app name as key and keyword list of configs as value) into an
  encoded config map.

      iex> ConfigSmuggler.encode([logger: [level: :info], my_app: [key: "value"]])
      {:ok, %{
          "elixir-logger-level" => ":info",
          "elixir-my_app-key" => "\"value\"",
      }}
  """
  @spec encode(decoded_configs) ::
          {:ok, encoded_config_map} | {:error, error_reason}
  def encode(decoded_configs) when is_list(decoded_configs) do
    try do
      {:ok,
       decoded_configs
       |> Enum.flat_map(&encode_app_and_opts/1)
       |> Enum.into(%{})}
    rescue
      _e -> {:error, :bad_input}
    end
  end

  def encode(_), do: {:error, :bad_input}

  defp encode_app_and_opts({app, opts}) when is_list(opts) do
    Encoder.encode_app_path_and_opts(app, [], opts)
  end

  @doc ~S"""
  Reads a config file and returns a map of encoded key/value pairs
  representing the configuration.  Respects `Mix.Config.import_config/1`.

      iex> ConfigSmuggler.encode_file("config/config.exs")
      {:ok, %{
        "elixir-logger-level" => ":info",
        # ...
      }}
  """
  @spec encode_file(String.t()) ::
          {:ok, encoded_config_map} | {:error, error_reason}
  def encode_file(filename) do
    try do
      {env, _files} = Mix.Config.eval!(filename)
      encode(env)
    rescue
      Code.LoadError -> {:error, :load_error}
      _e -> {:error, :bad_input}
    end
  end

  @doc ~S"""
  Encodes a single `Mix.Config.config/2` or `Mix.Config.config/3`
  statement into one or more encoded key/value pairs.

      iex> ConfigSmuggler.encode_statement("config :my_app, key1: :value1, key2: \"value2\"")
      {:ok, %{
          "elixir-my_app-key1" => ":value1",
          "elixir-my_app-key2" => "\"value2\"",
      }}

      iex> ConfigSmuggler.encode_statement("config :my_app, MyApp.Endpoint, url: [host: \"localhost\", port: 4444]")
      {:ok, %{
        "elixir-my_app-MyApp.Endpoint-url-host" => "\"localhost\"",
        "elixir-my_app-MyApp.Endpoint-url-port" => "4444",
      }}
  """
  @spec encode_statement(String.t()) ::
          {:ok, encoded_config_map} | {:error, error_reason}
  def encode_statement(stmt) when is_binary(stmt) do
    case String.split(stmt, ":", parts: 2) do
      [_, config] ->
        case Code.eval_string("[:#{config}]") do
          {[app, path | opts], _} when is_atom(path) ->
            {:ok,
             Encoder.encode_app_path_and_opts(app, [path], opts)
             |> Enum.into(%{})}

          {[app | opts], _} ->
            {:ok,
             Encoder.encode_app_path_and_opts(app, [], opts)
             |> Enum.into(%{})}

          _ ->
            {:error, :bad_input}
        end

      _ ->
        {:error, :bad_input}
    end
  end

  def encode_statement(_), do: {:error, :bad_input}
end
