defmodule ConfigSmuggler do
  @moduledoc """
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

  ## How It Works

  In a nutshell: the key begins with `elixir` and is a hyphen-separated
  "path" to the config value to be set.  The value is any valid Elixir
  term, encoded using normal Elixir syntax.

  ## Gotchas

  Atoms and modules are expected to follow standard Elixir convention,
  namely that atoms begin with a lowercase letter, modules begin with
  an uppercase letter, and neither contains any hyphen characters.

  If a config file or statement makes reference to `Mix.env()`, the current
  Mix env will be substituted.  This may be different than what the config
  file intended.
  """

  alias ConfigSmuggler.Encoder
  alias ConfigSmuggler.Decoder

  @type encoded_key :: String.t()
  @type encoded_value :: String.t()
  @type encoded_config_map :: %{encoded_key => encoded_value}
  @type decoded_configs :: [{atom, Keyword.t()}]
  @type error_reason :: String.t()
  @type validation_error :: {{encoded_key, encoded_value}, error_reason}

  @doc ~S"""
  Reads a config file and returns a map of encoded key/value pairs
  representing the configuration.  Respects `import_config`.

      iex> ConfigSmuggler.encode_file("config/config.exs")
      {:ok, %{
        # ...
      }}
  """
  @spec encode_file(String.t()) ::
          {:ok, encoded_config_map} | {:error, error_reason}
  def encode_file(filename) do
    try do
      {env, _files} = Mix.Config.eval!(filename)
      encode_env(env)
    rescue
      e -> {:error, e.description}
    end
  end

  @doc ~S"""
  Returns an encoded version of the given env, which is a keyword list
  keyed by app.

      iex> ConfigSmuggler.encode_env([logger: [level: :info], my_app: [key: "value"]])
      {:ok, %{
          "elixir-logger-level" => ":info",
          "elixir-my_app-key" => "\"value\""
      }}
  """
  @spec encode_env(Keyword.t()) ::
          {:ok, encoded_config_map} | {:error, error_reason}
  def encode_env(env) do
    {:ok,
     env
     |> Enum.flat_map(&Encoder.encode_app_and_opts/1)
     |> Enum.into(%{})}
  end

  @doc ~S"""
  Encodes a single `Mix.Config.config/2,3` statement into one or more
  encoded key/value pairs.

      iex> ConfigSmuggler.encode_statement("config :my_app, key1: :value1, key2: \"value2\"")
      {:ok, %{
          "elixir-my_app-key1" => ":value1",
          "elixir-my_app-key2" => "\"value2\""
      }}

      iex> ConfigSmuggler.encode_statement("config :my_app, MyApp.Endpoint, url: [host: \"localhost\", port: 4444]")
      {:ok, %{
        "elixir-my_app-MyApp.Endpoint-url-host" => "\"localhost\"",
        "elixir-my_app-MyApp.Endpoint-url-port" => "4444"
      }}
  """
  @spec encode_statement(String.t()) ::
          {:ok, encoded_config_map} | {:error, error_reason}
  def encode_statement(stmt) do
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
            {:error, "couldn't eval statement #{stmt}"}
        end

      _ ->
        {:error, "malformed statement #{stmt}"}
    end
  end

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
          {{"elixir-my_app-foo", "bogus value"}, "could not eval value"},
          {{"bad key", "22"}, "invalid key"},
        ]
      }
  """
  @spec decode(%{encoded_key => encoded_value}) ::
          {:ok, decoded_configs, [validation_error]}
  def decode(map) do
    Decoder.decode_and_merge(map)
  end
end
