defmodule ConfigSmuggler.Encoder do
  @moduledoc false

  @doc ~S"""
  Returns a list of encoded key/value tuples.
  """
  @spec encode_app_path_and_opts(atom, [atom], Keyword.t()) ::
          [{ConfigSmuggler.encoded_key(), ConfigSmuggler.encoded_value()}]
  def encode_app_path_and_opts(app, path, opts) when is_list(opts) do
    Enum.flat_map(opts, fn {key, value} ->
      case value do
        [{_k, _v} | _] -> encode_app_path_and_opts(app, path ++ [key], value)
        _ -> [{encode_key([app] ++ path ++ [key]), encode_value(value)}]
      end
    end)
  end

  def encode_app_path_and_opts(app, path, value) do
    [{encode_key([app | path]), encode_value(value)}]
  end

  @doc ~S"""
  Returns an encoded key using the given parts (atoms and
  modules).

     iex> ConfigSmuggler.Encoder.encode_key([:api, Api.Repo, :priv])
     "elixir-api-Api.Repo-priv"
  """
  @spec encode_key([atom]) :: ConfigSmuggler.encoded_key()
  def encode_key(parts) do
    "elixir-" <>
      (parts
       |> Enum.map(&(&1 |> to_string |> String.replace_leading("Elixir.", "")))
       |> Enum.join("-"))
  end

  @doc ~S"""
  Returns an encoded value.
  """
  @spec encode_value(any) :: ConfigSmuggler.encoded_value()
  def encode_value(value) do
    inspect(value, limit: :infinity, printable_limit: :infinity)
  end
end
