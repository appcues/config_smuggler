defmodule ConfigSmuggler.Apply do
  @moduledoc false

  alias ConfigSmuggler.Decoder

  @doc ~S"""
  Applies the configs specified in an encoded config map to the current
  environment.  Any decoding errors are ignored.
  """
  @spec apply_encoded(ConfigSmuggler.encoded_config_map()) :: :ok
  def apply_encoded(encoded_config_map) do
    {:ok, decoded_configs, _errors} =
      Decoder.decode_and_merge(encoded_config_map)

    apply_decoded(decoded_configs)
  end

  @doc ~S"""
  Applies the configs specified in an Elixir-native config to the current
  environment.
  """
  @spec apply_encoded(ConfigSmuggler.decoded_configs()) :: :ok
  def apply_decoded(decoded_configs)

  def apply_decoded([]), do: :ok

  def apply_decoded([{app, opts} | rest]) do
    apply_config(app, opts)
    apply_decoded(rest)
  end

  defp apply_config(app, config) do
    old_config = app |> Application.get_all_env()

    Mix.Config.merge([{app, old_config}], [{app, config}])
    |> Enum.each(&put_opts_in_env/1)
  end

  defp put_opts_in_env({app, opts}) do
    Enum.each(opts, fn {k, v} -> Application.put_env(app, k, v) end)
  end
end
