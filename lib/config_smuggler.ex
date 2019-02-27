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

  @doc ~S"""
  Encodes one or more Elixir config statements (in `Mix.Config`/`config.exs`-
  style syntax) into string keys and values.

      iex> ConfigSmuggler.encode("config :my_app, some_key: 22")
      {:ok, %{"elixir-my_app-some_key" => "22"}}

      iex> ConfigSmuggler.encode("config :my_app, MyApp.Endpoint, url: [host: \"localhost\", port: 4444]")
      {:ok, %{
        "elixir-my_app-MyApp.Endpoint-url-host" => "\"localhost\"",
        "elixir-my_app-MyApp.Endpoint-url-port" => "4444"
      }}

  You can even pass in the contents of a `config.exs` file directly:

      iex> "config/config.exs" |> File.read! |> ConfigSmuggler.encode
      {:ok, %{
        # ...
      }}
  """
  @spec encode(String.t) :: {:ok, %{String.t => String.t}} | {:error, String.t}
  def encode(str) do
    ConfigSmuggler.Encoder.encode(str)
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
        my_app: [
          {:some_key, 22},
          {MyApp.Endpoint, [
            url: [
              host: "localhost",
              port: 4444
            ]
          ]}
        ],
        logger: [level: :info]
      ]}
  """
  @spec decode(%{String.t => String.t}) :: {:ok, Keyword.t} | {:error, String.t}
  def decode(map) do
    ConfigSmuggler.Decoder.decode_and_merge(map)
  end
end
