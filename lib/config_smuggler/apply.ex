defmodule ConfigSmuggler.Apply do
  @moduledoc false

  alias ConfigSmuggler.Decoder

  @doc ~S"""
  Applies the configs specified in an encoded config map to the current
  environment.  Any decoding errors are ignored.
  """
  @spec apply_encoded(ConfigSmuggler.encoded_config_map()) ::
          :ok | {:error, ConfigSmuggler.error_reason()}
  def apply_encoded(encoded_config_map) do
    with {:ok, decoded_configs, _errors} <-
           Decoder.decode_and_merge(encoded_config_map) do
      apply_decoded(decoded_configs)
    end
  end

  @doc ~S"""
  Applies the configs specified in an Elixir-native config to the current
  environment.
  """
  @spec apply_encoded(ConfigSmuggler.decoded_configs()) ::
          :ok | {:error, ConfigSmuggler.error_reason()}
  def apply_decoded(decoded_configs)

  def apply_decoded([]), do: :ok

  def apply_decoded([{app, opts} | rest]) do
    apply_config(app, opts)
    apply_decoded(rest)
  end

  def apply_decoded(_), do: {:error, :bad_input}

  defp apply_config(app, config) do
    old_config = Application.get_all_env(app)

    Config.Reader.merge([{app, old_config}], [{app, config}])
    |> Enum.each(&put_opts_in_env/1)
  end

  defp put_opts_in_env({app, opts}) do
    Enum.each(opts, fn {k, v} ->
      Application.put_env(app, k, v, persistent: true)
    end)
  end
end
