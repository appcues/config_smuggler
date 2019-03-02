defmodule ConfigSmuggler.Decoder do
  @moduledoc false

  @doc ~S"""
  Turns a map of encoded key/value pairs into decoded configs that are
  ready for e.g., `Mix.Config.merge/2`, also returning any invalid
  key/value pairs.
  """
  @spec decode_and_merge(ConfigSmuggler.encoded_config_map()) ::
          {:ok, ConfigSmuggler.decoded_configs(),
           [
             {{ConfigSmuggler.encoded_key(), ConfigSmuggler.encoded_value()},
              ConfigSmuggler.error_reason()},
           ]}
          | {:error, ConfigSmuggler.error_reason()}
  def decode_and_merge(%{} = config_map) do
    ## decoded stuff goes under `valid`, non-decoded stuff under `invalid`
    validated_pairs =
      Enum.reduce(config_map, %{valid: [], invalid: []}, fn {k, v}, acc ->
        case decode_pair(k, v) do
          {:ok, app, opts} -> %{acc | valid: [{app, opts} | acc.valid]}
          {:error, error} -> %{acc | invalid: [{{k, v}, error} | acc.invalid]}
        end
      end)

    merged_config =
      Enum.reduce(validated_pairs.valid, [], fn {app, opts}, acc ->
        Mix.Config.merge(acc, [{app, opts}])
      end)

    {:ok, merged_config, validated_pairs.invalid}
  end

  def decode_and_merge(_), do: {:error, :bad_input}

  @doc ~S"""
  Decodes a key-value pair from ConfigSmuggler.

  Returns `app` and `opts` that are in the same format expected by
  `Mix.Config.config/2`, though the latter function is not available
  at runtime.

  Example:

      iex> ConfigSmuggler.Decoder.decode_pair(
      ...>   "elixir-api-Api.Repo-loggers",
      ...>  "[{Ecto.LogEntry, :log, []}]"
      ...> )
      {:ok, :api, [{Api.Repo, [loggers: [{Ecto.LogEntry, :log, []}]]}]}
  """
  @spec decode_pair(
          ConfigSmuggler.encoded_key(),
          ConfigSmuggler.encoded_value()
        ) :: {:ok, atom, Keyword.t()} | {:error, ConfigSmuggler.error_reason()}
  def decode_pair("elixir-" <> key, value) do
    with {:ok, app, path} <- decode_stripped_key(key),
         {:ok, evaled_value} <- eval(value) do
      {:ok, app, nest_value(path, evaled_value)}
    end
  end

  def decode_pair(_key, _value), do: {:error, :bad_key}

  defp nest_value(path, value) do
    path |> Enum.reverse() |> nest_value_in_reverse(value)
  end

  defp nest_value_in_reverse([], value), do: value

  defp nest_value_in_reverse([first | rest], value) do
    nest_value_in_reverse(rest, [{first, value}])
  end

  @doc ~S"""
  Splits an encoded key into app and path, casting to atom or
  module as it goes.

      iex> ConfigSmuggler.Decoder.decode_key("elixir-api-Api.Repo-priv")
      {:ok, :api, [Api.Repo, :priv]}
  """
  @spec decode_key(ConfigSmuggler.encoded_key()) ::
          {:ok, atom, [atom]} | {:error, ConfigSmuggler.error_reason()}
  def decode_key("elixir-" <> key) do
    decode_stripped_key(key)
  end

  def decode_key(_key), do: {:error, :bad_key}

  defp decode_stripped_key(key) do
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

  ## By law of symmetry, this should be a public function `decode_value/1`,
  ## but I do not consider it wise to expose eval so barely.
  defp eval(value) do
    try do
      {evaled_value, _binding} = Code.eval_string(value)
      {:ok, evaled_value}
    rescue
      _e -> {:error, :bad_value}
    end
  end
end
