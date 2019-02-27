defmodule ConfigSmuggler.Decoder do
  @moduledoc false

  @doc ~S"""
  Converts a map of encoded Opscues config keys and values into a
  keyword list of configs (as used by `Mix.Config.merge/2`).

      iex> ConfigSmuggler.Decoder.decode_and_merge(%{
      ...>   "elixir-api-Api.Repo-priv" => "\"priv/repo\"",
      ...>   "elixir-logger-level" => ":info",
      ...>   "elixir-api-ballz-omg" => ":wat",
      ...>   "elixir-api-cache_ttl" => "60000",
      ...>   "elixir-api-Api.Repo-destroy_data" => "false",
      ...>   "elixir-api-ballz-lol" => "true"
      ...> })
      {:ok, [
        api: [
          {Api.Repo, [destroy_data: false, priv: "priv/repo"]},
          {:ballz, [lol: true, omg: :wat]},
          {:cache_ttl, 60000}
        ],
        logger: [level: :info]
      ]}
  """
  @spec decode_and_merge(%{String.t() => String.t()}) :: {:ok, Keyword.t()} | {:error, String.t()}
  def decode_and_merge(config_map) do
    config_map
    |> Enum.to_list()
    |> do_decode_and_merge([])
  end

  defp do_decode_and_merge([], acc), do: {:ok, acc}

  defp do_decode_and_merge([{key, value} | rest], acc) do
    with {:ok, app, opts} <- decode_pair(key, value) |> IO.inspect do
      do_decode_and_merge(rest, Mix.Config.merge(acc, [{app, opts}]))
    end
  end

  @doc ~S"""
  Decodes a key-value pair from ConfigSmuggler.

  Returns `app` and `opts` that are in the same format expected by
  `Mix.Config.config/2`, though the latter function is not available
  at runtime.

  *DO NOT* pass untrusted input to this function!

  Example:

      iex> ConfigSmuggler.Decoder.decode_pair(
      ...>   "elixir-api-Api.Repo-loggers",
      ...>  "[{Ecto.LogEntry, :log, []}]"
      ...> )
      {:ok, :api, [{Api.Repo, [loggers: [{Ecto.LogEntry, :log, []}]]}]}
  """
  @spec decode_pair(String.t(), String.t()) :: {:ok, atom, Keyword.t()} | {:error, String.t()}
  def decode_pair("elixir-" <> key, value) do
    with {:ok, app, path} <- decode_key(key),
         {:ok, evaled_value} <- eval(value) do
      {:ok, app, nest_value(path, evaled_value)}
    end
  end

  def decode_pair(key, value) do
    app = Application.get_env(:opscues_config, :app)
    {:ok, app, [{to_atom(key), maybe_cast_to_integer(value)}]}
  end

  defp nest_value(path, value) do
    path |> Enum.reverse |> nest_value_in_reverse(value)
  end

  defp nest_value_in_reverse([], value), do: value

  defp nest_value_in_reverse([first | rest], value) do
    nest_value_in_reverse(rest, {first, value})
  end

  defp to_atom(a) when is_atom(a), do: a
  defp to_atom(s) when is_binary(s), do: String.to_atom(s)

  defp maybe_cast_to_integer(value) do
    case Integer.parse(value) do
      {parsed, ""} -> parsed
      _ -> value
    end
  end

  @doc ~S"""
  Splits an encoded key into app and path, casting to atom or
  module as it goes.

      iex> ConfigSmuggler.Decoder.decode_key("elixir-api-Api.Repo-priv")
      {:ok, :api, [Api.Repo, :priv]}
  """
  def decode_key("elixir-" <> key), do: decode_key(key)

  def decode_key(key) do
    [app | path] =
      key
      |> String.split("-")
      |> Enum.map(&to_atom_or_module/1)

    {:ok, app, path}
  end

  defp to_atom_or_module(str) do
    case str |> String.to_charlist() |> List.first() do
      c when c in ?a..?z -> String.to_atom(str)
      _ -> String.to_atom("Elixir." <> str)
    end
  end

  defp eval(value) do
    try do
      {evaled_value, _binding} = Code.eval_string(value)
      {:ok, evaled_value}
    rescue
      e -> {:error, e.message}
    end
  end
end

