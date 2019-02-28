defmodule ConfigSmuggler do
  @moduledoc """
  ConfigSmuggler is a library for converting Elixir-style configuration
  statements into string-encoded key/value pairs.  It's designed to make
  it easier to use platform-agnostic configuration systems with Elixir
  services.

  In a nutshell: the key begins with `elixir` and is a hyphen-separated
  "path" to the config value to be set.  The value is any valid Elixir
  term, encoded using Elixir syntax.

  IMPORTANT!  Values are evaluated using `Code.eval_string/1`.  This means
  that `ConfigSmuggler.decode/1` *must not* be used on untrusted or user-
  supplied data!

  See `encode/1` and `decode/1` for usage examples.
  """

  alias ConfigSmuggler.Encoder
  alias ConfigSmuggler.Decoder

  @doc ~S"""
  Reads a config file and returns a map of encoded key/value pairs
  representing the configuration.  Respects `import_config`.

  WARNING! This function `eval`s its input, and should not be used on
  untrusted data.

      iex> ConfigSmuggler.encode_file("config/config.exs")
      {:ok, %{
        # ...
      }}
  """
  @spec encode_file(String.t) :: {:ok, %{String.t => String.t}} | {:error, String.t}
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
  @spec encode_env(Keyword.t) :: {:ok, %{String.t => String.t}} | {:error, String.t}
  def encode_env(env) do
    {:ok,  env
    |> Enum.flat_map(&Encoder.encode_app_and_opts/1)
    |> Enum.into(%{})
  }
  end

  @doc ~S"""
  Encodes a single `Mix.Config.config/2,3` statement into one or more
  encoded key/value pairs.

  WARNING! This function `eval`s its input, and should not be used on
  untrusted data.

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
  @spec encode_statement(String.t) :: {:ok, %{String.t => String.t}} | {:error, String.t}
  def encode_statement(stmt) do
    case String.split(stmt, ":", parts: 2) do
      [_, config] ->
        case Code.eval_string("[:#{config}]") do
          {[app, path | opts], _} when is_atom(path) ->
            {:ok, Encoder.encode_app_path_and_opts(app, [path], opts) |> Enum.into(%{})}
          {[app | opts], _} ->
            {:ok, Encoder.encode_app_path_and_opts(app, [], opts) |> Enum.into(%{})}
          _ ->
            {:error, "couldn't eval statement #{stmt}"}
        end

      _ ->
        {:error, "malformed statement #{stmt}"}
    end
  end

  @doc ~S"""
  Decodes a map of string-encoded key/value pairs into a keyword list of
  Elixir configs, keyed by app.

      iex> ConfigSmuggler.decode(%{
      ...>   "elixir-my_app-some_key" => "22",
      ...>   "elixir-my_app-MyApp.Endpoint-url-host" => "\"localhost\"",
      ...>   "elixir-logger-level" => ":info",
      ...>   "elixir-my_app-MyApp.Endpoint-url-port" => "4444"
      ...> })
      {:ok, [
        logger: [level: :info],
        my_app: [
          {MyApp.Endpoint, [
            url: [
              host: "localhost",
              port: 4444
            ]
          ]},
          {:some_key, 22},
        ]
      ]}
  """
  @spec decode(%{String.t => String.t}) :: {:ok, Keyword.t} | {:error, String.t}
  def decode(map) do
    ConfigSmuggler.Decoder.decode_and_merge(map)
  end
end
