defmodule ConfigSmugglerTest do
  use ExUnit.Case, async: true
  doctest ConfigSmuggler
  doctest ConfigSmuggler.Apply
  doctest ConfigSmuggler.Decoder
  doctest ConfigSmuggler.Encoder

  setup do
    id = :crypto.strong_rand_bytes(5) |> Base.encode32() |> String.downcase()
    app = String.to_atom("app_" <> id)

    encoded_config_map = %{
      "elixir-#{app}-some_key" => ":some_value",
      "elixir-#{app}-Some.Module-other_key" => "\"other value\"",
      "elixir-#{app}-Some.Module-deep_key" => ":deep_value",
      "bad key" => "22",
      "elixir-#{app}-Some.Module-bad_value" => "won't work",
    }

    decoded_configs = [
      {app,
       [
         {:some_key, :some_value},
         {Some.Module, [
             other_key: "other value",
             deep_key: :deep_value,
           ]},
       ]},
    ]

    errors = [
      {{"elixir-#{app}-Some.Module-bad_value", "won't work"}, :bad_value},
      {{"bad key", "22"}, :bad_key},
    ]

    {:ok,
     app: app,
     encoded_config_map: encoded_config_map,
     decoded_configs: decoded_configs,
     errors: errors}
  end

  describe "apply/1" do
    test "handles encoded config map", context do
      app = context.app
      config_map = context.encoded_config_map

      assert(:ok = ConfigSmuggler.apply(config_map))
      assert(:some_value = Application.get_env(app, :some_key))

      assert(
        [other_key: "other value", deep_key: :deep_value] =
          Application.get_env(app, Some.Module)
      )
    end

    test "handles decoded configs", context do
      app = context.app
      configs = context.decoded_configs

      assert(:ok = ConfigSmuggler.apply(configs))
      assert(:some_value = Application.get_env(app, :some_key))

      assert(
        [other_key: "other value", deep_key: :deep_value] =
          Application.get_env(app, Some.Module)
      )
    end

    test "handles bad inputs" do
      assert({:error, :bad_input} = ConfigSmuggler.apply("wat"))
      assert({:error, :bad_input} = ConfigSmuggler.apply(22))
      assert({:error, :bad_input} = ConfigSmuggler.apply(:ok))
      assert({:error, :bad_input} = ConfigSmuggler.apply([1, 2, 3]))
    end
  end

  describe "decode/1" do
    test "decodes a config map", context do
      assert(
        {:ok, decoded_configs, errors} =
          ConfigSmuggler.decode(context.encoded_config_map)
      )

      assert(decoded_configs == context.decoded_configs)
      assert(errors == context.errors)
    end

    test "handles bad inputs" do
      assert({:error, :bad_input} = ConfigSmuggler.decode([]))
      assert({:error, :bad_input} = ConfigSmuggler.decode("whee"))
      assert({:error, :bad_input} = ConfigSmuggler.decode(3.14))
      assert({:error, :bad_input} = ConfigSmuggler.decode(nil))
    end
  end

  describe "encode/1" do
    test "encodes native configs", context do
      assert({:ok, config_map} = ConfigSmuggler.encode(context.decoded_configs))
      config_map_without_errors =
        context.errors
        |> Enum.reduce(context.encoded_config_map, fn ({{k,_v},_e}, acc) ->
          Map.delete(acc, k)
        end)
      assert(config_map == config_map_without_errors)
    end

    test "handles bad inputs" do
      assert({:error, :bad_input} = ConfigSmuggler.encode("blorp"))
      assert({:error, :bad_input} = ConfigSmuggler.encode(22/7))
      assert({:error, :bad_input} = ConfigSmuggler.encode([1, 2, 3]))
      assert({:error, :bad_input} = ConfigSmuggler.encode([a: :b]))
      assert({:error, :bad_input} = ConfigSmuggler.encode(%{}))
    end
  end

  describe "encode_file/1" do
    test "encodes a file" do
      config_map = %{
        "elixir-config_smuggler-some_key" => ":some_value",
        "elixir-config_smuggler-other_key" => "\"other value\"",
        "elixir-config_smuggler-ConfigSmuggler-omg" => ":lol",
        "elixir-config_smuggler-ConfigSmuggler-timeout" => "5000",
        "elixir-config_smuggler-ConfigSmuggler-kwlist-yes" => "true",
        "elixir-config_smuggler-ConfigSmuggler-kwlist-no" => "false",
      }
      assert({:ok, config_map} == ConfigSmuggler.encode_file("config/test.exs"))
    end

    test "returns errors on broken input" do
      assert({:error, :load_error} = ConfigSmuggler.encode_file("nope.txt"))
      assert({:error, :bad_input} = ConfigSmuggler.encode_file("README.md"))
      assert({:error, :bad_input} = ConfigSmuggler.encode_file("assets/smuggler.jpg"))
    end
  end

  describe "encode_statement/1" do
    test "returns errors on broken input" do
      assert({:error, :bad_input} = ConfigSmuggler.encode_statement(:nope))
      assert({:error, :bad_input} = ConfigSmuggler.encode_statement("config wat"))
    end
  end
end
