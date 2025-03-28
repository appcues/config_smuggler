defmodule Mix.Tasks.Smuggle do
  @moduledoc ~S"""
  ConfigSmuggler provides the `mix smuggle` task, which encodes
  `config.exs`-style files into JSON-formatted key/value pairs.

  Usage: `mix smuggle encode <filename.exs>`
  """
  use Mix.Task

  defp insp(v), do: ConfigSmuggler.Encoder.encode_value(v)

  @impl true
  @shortdoc "Encodes a config.exs-style file into JSON keys and values"
  def run(["encode", filename]) do
    with {:ok, encoded_config_map} <- ConfigSmuggler.encode_file(filename) do
      data =
        encoded_config_map
        |> Enum.map(fn {k, v} -> "#{insp(k)}:#{insp(v)}" end)
        |> Enum.join(",")

      IO.puts("{" <> data <> "}")
    else
      {:error, reason} ->
        Mix.shell().error("Error: #{insp(reason)}")
        System.halt(1)
    end
  end

  def run(_args) do
    Mix.shell().error("Usage: mix smuggle encode <filename.exs>")
    System.halt(1)
  end
end
