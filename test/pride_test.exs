if Code.ensure_loaded?(Uniq.UUID) do
  defmodule PrideTest do
    use ExUnit.Case, async: true

    alias Uniq.UUID

    defmodule TestSchema do
      use Ecto.Schema

      @primary_key {:id, Pride, prefix: "test", autogenerate: true}
      @foreign_key_type Pride

      schema "test" do
        belongs_to(:test, TestSchema)
      end
    end

    @params Pride.init(
              schema: TestSchema,
              field: :id,
              primary_key: true,
              autogenerate: true,
              prefix: "test"
            )
    @belongs_to_params Pride.init(schema: TestSchema, field: :test, foreign_key: :test_id)
    @loader nil
    @dumper nil

    @test_prefixed_uuid "test_3TUIKuXX5mNO2jSA41bsDx"
    @test_uuid UUID.to_string("7232b37d-fc13-44c0-8e1b-9a5a07e24921", :raw)
    @test_prefixed_uuid_with_leading_zero "test_02tREKF6r6OCO2sdSjpyTm"
    @test_uuid_with_leading_zero UUID.to_string("0188a516-bc8c-7c5a-9b68-12651f558b9e", :raw)
    @test_prefixed_uuid_null "test_0000000000000000000000"
    @test_uuid_null UUID.to_string("00000000-0000-0000-0000-000000000000", :raw)
    @test_prefixed_uuid_invalid_characters "test_" <> String.duplicate(".", 32)
    @test_uuid_invalid_characters String.duplicate(".", 22)
    @test_prefixed_uuid_invalid_format "test_" <> String.duplicate("x", 31)
    @test_uuid_invalid_format String.duplicate("x", 21)

    test "cast/2" do
      assert Pride.cast(@test_prefixed_uuid, @params) == {:ok, @test_prefixed_uuid}

      assert Pride.cast(@test_prefixed_uuid_with_leading_zero, @params) ==
               {:ok, @test_prefixed_uuid_with_leading_zero}

      assert Pride.cast(@test_prefixed_uuid_null, @params) == {:ok, @test_prefixed_uuid_null}
      assert Pride.cast(nil, @params) == {:ok, nil}
      assert {:error, _} = Pride.cast("otherprefix" <> @test_prefixed_uuid, @params)
      assert {:error, _} = Pride.cast(@test_prefixed_uuid_invalid_characters, @params)
      assert {:error, _} = Pride.cast(@test_prefixed_uuid_invalid_format, @params)
      assert Pride.cast(@test_prefixed_uuid, @belongs_to_params) == {:ok, @test_prefixed_uuid}
    end

    test "load/3" do
      assert Pride.load(@test_uuid, @loader, @params) == {:ok, @test_prefixed_uuid}

      assert Pride.load(@test_uuid_with_leading_zero, @loader, @params) ==
               {:ok, @test_prefixed_uuid_with_leading_zero}

      assert Pride.load(@test_uuid_null, @loader, @params) == {:ok, @test_prefixed_uuid_null}
      assert Pride.load(@test_uuid_invalid_characters, @loader, @params) == :error
      assert Pride.load(@test_uuid_invalid_format, @loader, @params) == :error
      assert Pride.load(@test_prefixed_uuid, @loader, @params) == :error
      assert Pride.load(nil, @loader, @params) == {:ok, nil}
      assert Pride.load(@test_uuid, @loader, @belongs_to_params) == {:ok, @test_prefixed_uuid}
    end

    test "dump/3" do
      assert Pride.dump(@test_prefixed_uuid, @dumper, @params) == {:ok, @test_uuid}

      assert Pride.dump(@test_prefixed_uuid_with_leading_zero, @dumper, @params) ==
               {:ok, @test_uuid_with_leading_zero}

      assert Pride.dump(@test_prefixed_uuid_null, @dumper, @params) == {:ok, @test_uuid_null}
      assert Pride.dump(@test_uuid, @dumper, @params) == :error
      assert Pride.dump(nil, @dumper, @params) == {:ok, nil}
      assert Pride.dump(@test_prefixed_uuid, @dumper, @belongs_to_params) == {:ok, @test_uuid}
    end

    test "autogenerate/1" do
      assert prefixed_uuid = Pride.autogenerate(@params)
      assert {:ok, uuid} = Pride.dump(prefixed_uuid, nil, @params)
      assert {:ok, %UUID{format: :raw, version: 7}} = UUID.parse(uuid)
    end
  end
end
