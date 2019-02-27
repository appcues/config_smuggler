defmodule ConfigSmuggler.Encoder do
  @moduledoc false

  @doc ~S|
  Turns a string containing one or more `Mix.Config.config/2,3`
  statements into a map containing one or more encoded key-value
  pairs.  If a `config.exs` file doesn't have logic in it, this
  function will convert it for use with ConfigSmuggler.

      iex> ConfigSmuggler.Encoder.encode("config :api, mangle_data: true")
      {:ok, %{"elixir-api-mangle_data" => "true"}}

      iex> ConfigSmuggler.Encoder.encode("""
      ...> # This is a comment lolol
      ...> use Mix.Config
      ...>
      ...> config :logger, level: :info  # the most useless loglevel
      ...> config :api, Api.Repo, priv: "priv/repo"
      ...>
      ...> config :opscues_config, app: :api, facet: "trashpacker"
      ...> import_config "#{Mix.env()}.exs"
      ...> """)
      {:ok, %{
          "elixir-logger-level" => ":info",
          "elixir-api-Api.Repo-priv" => "\"priv/repo\"",
          "elixir-opscues_config-app" => ":api",
          "elixir-opscues_config-facet" => "\"trashpacker\""
      }}

  |
  @spec encode(String.t()) :: {:ok, %{String.t() => String.t()}} | {:error, String.t()}
  def encode(string) do
    try do
      {:ok,
       string
       |> String.replace(~r/#.*$/m, "")
       |> String.replace(~r/^ \s* import_config \s+ .+ $/mx, "")
       |> String.replace(~r/^ \s* use \s+ .+ $/mx, "")
       |> String.split(~r/^ \s* config \s+ :/mx, trim: true)
       |> Enum.map(&"[:#{&1}]")
       |> Enum.map(&eval!/1)
       |> Enum.flat_map(&transform/1)
       |> Enum.into(%{})}
    rescue
      e -> {:error, e.message}
    end
  end

  @doc ~S"""
  Returns an encoded Opscues config key using the given parts (atoms and
  modules).

     iex> ConfigSmuggler.Encoder.encode_key([:api, Api.Repo, :priv])
     "elixir-api-Api.Repo-priv"
  """
  def encode_key(parts) do
    "elixir-" <>
      (parts
       |> Enum.map(&(&1 |> to_string |> String.replace_leading("Elixir.", "")))
       |> Enum.join("-"))
  end

  ## Emits a list of {key, value} tuples
  defp transform(evaled_config, acc \\ [])

  defp transform([app, {key, value} | rest], acc) do
    transform(
      [app | rest],
      [{encode_key([app, key]), inspect(value)} | acc]
    )
  end

  defp transform([app, subheading, {key, value} | rest], acc) do
    transform(
      [app, subheading | rest],
      [{encode_key([app, subheading, key]), inspect(value)} | acc]
    )
  end

  defp transform([_app, _subheading], acc), do: acc

  defp transform([_app], acc), do: acc

  defp transform([], acc), do: acc

  defp eval!(str) do
    {value, _binding} = Code.eval_string(str)
    value
  end
end

