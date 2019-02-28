defmodule ConfigSmuggler.Encoder do
  @moduledoc false

  def encode_app_and_opts({app, opts}) do
    encode_app_path_and_opts(app, [], opts)
  end

  def encode_app_path_and_opts(app, path, opts) when is_list(opts) do
    Enum.flat_map(opts, fn {key, value} ->
      case value do
        [{_k, _v} | _] -> encode_app_path_and_opts(app, path ++ [key], value)
        _ -> [{encode_key([app] ++ path ++ [key]), inspect(value)}]
      end
    end)
  end

  def encode_app_path_and_opts(app, path, value) do
    [{encode_key([app | path]), inspect(value)}]
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
end
