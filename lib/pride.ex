defmodule Pride do
  @doc """
  Generates prefixed base62 encoded UUIDv7.
  Based on https://danschultzer.com/posts/prefixed-base62-uuidv7-object-ids-with-ecto

  ## Examples

      @primary_key {:id, Pride, prefix: "acct", autogenerate: true}
      @foreign_key_type Pride
  """
  use Ecto.ParameterizedType
  import Untangle, except: [dump: 3]

  @rust_disabled Application.compile_env(:pride, :use_rust, true) != true
  # FIXME: uuidv7 1.0+ no longer uses rust (not sure what makes it unique vs uniq now)

  @impl true
  @doc "Callback to convert the options specified in the field macro into parameters to be used in other callbacks.
  This function is called at compile time, and should raise if invalid values are specified. It is idiomatic that the parameters returned from this are a map. field and schema will be injected into the options automatically."
  def init(opts) do
    schema = Keyword.fetch!(opts, :schema)
    field = Keyword.fetch!(opts, :field)

    prefix = Keyword.get(opts, :prefix)

    case opts[:primary_key] do
      true ->
        cond do
          prefix ->
            %{
              primary_key: true,
              schema: schema,
              prefix: prefix,
              __pride__: init_pride(schema, field)
            }

          opts[:allow_unprefixed] ->
            %{
              primary_key: true,
              schema: schema
            }

          true ->
            raise "`:prefix` option is required"
        end

      _any ->
        %{
          schema: schema,
          field: field,
          # prefix: prefix,
          __pride__: init_pride(schema, field)
        }
    end
  end

  if @rust_disabled do
    defp init_pride(schema, field) do
      Uniq.UUID.init(schema: schema, field: field, version: 7, default: :raw, dump: :raw)
    end
  else
    defp init_pride(_schema, _field) do
      true
    end
  end

  @impl true
  def type(_params), do: :uuid

  @impl true
  @doc "Casts the given input to the ParameterizedType with the given parameters."
  def cast(nil, _params), do: {:ok, nil}

  def cast(data, params) do
    with {:ok, prefix, _uuid} <- unfurl_object_id(data, params),
         {prefix, prefix} <- {prefix, prefix(params)} do
      {:ok, data}
    else
      :error ->
        error(data, "Not a valid Prefixed UUIDv7")
        {:error, message: "Not a valid Prefixed UUIDv7"}

      {_, nil} ->
        warn(params, "prefix for primary key not found: #{inspect(data)}")
        # {:error, message: "prefix for primary key not found"}
        #  we pretend all is well here so we can cast across assocs and mixins...
        {:ok, data}

      _ ->
        error(params, "The ID's object type does not match the schema type: #{inspect(data)}")
        {:error, message: "The ID's object type does not match the schema type"}
    end
  end

  def valid?(string, params \\ nil)
  def valid?(nil, _params), do: true

  def valid?(string, nil) when is_binary(string) do
    with [_prefix, id] when byte_size(id) == 22 <- String.split(string, "_"),
         {:ok, uuid} <- printable_decode(id) do
      check_valid?(uuid)
    else
      _ -> false
    end
  end

  def valid?(string, params) when is_binary(string) do
    with {:ok, prefix_from_string, uuid} <- unfurl_object_id(string, params) do
      if prefix_from_schema = prefix(params) do
        prefix_from_string == prefix_from_schema and check_valid?(uuid)
      else
        # if we don't have a prefix from schema, assume valid if the format is right
        check_valid?(uuid)
      end
    else
      _ -> false
    end
  end
  
  def valid?(_, _), do: false

  def valid_or_uuid(string, params) when is_binary(string) do
    with {:ok, prefix_from_string, uuid} <- unfurl_object_id(string, params) do
      if prefix_from_schema = prefix(params) do
        prefix_from_string == prefix_from_schema and check_valid?(uuid)
      else
        # if we don't have a prefix from schema, assume valid if the format is right
        check_valid?(uuid)
      end || uuid
    else
      _ -> false
    end
  end

  if @rust_disabled do
    defp check_valid?(uuid) do
      Uniq.UUID.valid?(uuid, version: 7)
    end
  else
    defp check_valid?(uuid) do
      UUIDv7.cast(uuid) != :error
    end
  end

  @impl true
  @doc "Loads the given term into a ParameterizedType.
  It receives a loader function in case the parameterized type is also a composite type. In order to load the inner type, the loader must be called with the inner type and the inner value as argument."
  def load(data, loader, params) do
    prefix = prefix(params)

    case not is_nil(prefix) and do_load(data, loader, params) do
      {:ok, nil} -> {:ok, nil}
      {:ok, uuid} -> {:ok, uuid_to_object_id(uuid, prefix)}
      :error -> :error
      false -> :error
    end
  end

  defp do_load(nil, _loader, _params), do: {:ok, nil}

  if @rust_disabled do
    defp do_load(data, loader, params) do
      Uniq.UUID.load(data, loader, pride!(params))
    end
  else
    defp do_load(data, _loader, _params) do
      UUIDv7.load(data)
      #  TODO: support loader?
    end
  end

  @impl true
  @doc "Dumps the given term into an Ecto native type.
  It receives a dumper function in case the parameterized type is also a composite type. In order to dump the inner type, the dumper must be called with the inner type and the inner value as argument."
  def dump(nil, _, _), do: {:ok, nil}

  def dump(value, dumper, params) do
    case unfurl_object_id(value, params) |> debug() do
      {:ok, _prefix, uuid} ->
        if @rust_disabled do
          Uniq.UUID.dump(uuid, dumper, pride(params) || %{dump: :raw})
        else
          #  TODO: support dumper?
          UUIDv7.dump(uuid)
        end

      :error ->
        :error
    end
  end

  @impl true
  @doc "Generates a loaded version of the data."
  def autogenerate(params) do
    generate_uuid(params)
    |> uuid_to_object_id(prefix!(params))
  end

  if @rust_disabled do
    defp generate_uuid(params) do
      Uniq.UUID.autogenerate(pride!(params))
    end
  else
    defp generate_uuid(_params) do
      UUIDv7.generate()
    end

    def generate(ms, params) when is_integer(ms) do
      UUIDv7.generate(ms)
      |> uuid_to_object_id(prefix!(params))
    end
  end

  @impl true
  if @rust_disabled do
    def embed_as(format, params), do: Uniq.UUID.embed_as(format, pride!(params))
  else
    def embed_as(format, _params), do: UUIDv7.embed_as(format)
  end

  @impl true
  def equal?(a, b, params) when is_nil(a) and not is_nil(b), do: false
  def equal?(a, b, params) when not is_nil(a) and is_nil(b), do: false

  if @rust_disabled do
    def equal?(a, b, params), do: Uniq.UUID.equal?(a, b, pride!(params))
  else
    def equal?(a, b, _params), do: UUIDv7.equal?(a, b)
  end

  defp unfurl_object_id(string, _params) when is_binary(string) do
    with [prefix, id] when byte_size(id) == 22 <- String.split(string, "_"),
         {:ok, uuid} <- printable_decode(id) do
      {:ok, prefix, uuid}
    else
      _ -> :error
    end
  end

  defp uuid_to_object_id(uuid, prefix) do
    "#{prefix}_#{printable_encode(uuid)}"
  end

  defp prefix!(%{primary_key: true, prefix: prefix}),
    do: prefix || raise("prefix for relation primary key not found")

  defp prefix!(params) do
    prefix(params) || raise("prefix for relation primary key not found")
  end

  defp prefix(%{primary_key: true, prefix: prefix}), do: prefix
  # If we deal with a belongs_to association we need to fetch the prefix from
  # the associations schema module
  defp prefix(%{schema: schema, field: field}) do
    %{related: schema, related_key: field} = schema.__schema__(:association, field)
    prefix(schema, field)
  end

  defp prefix(_), do: nil

  def prefix(schema, field) when is_atom(schema) do
    case schema.__schema__(:type, field) do
      {:parameterized, {_module, %{prefix: prefix}}} -> prefix
      {:parameterized, _module, %{prefix: prefix}} -> prefix
      _ -> nil
    end
  end

  def params(schema, field) when is_atom(schema) do
    case schema.__schema__(:type, field) do
      {:parameterized, {_module, params}} -> params
      {:parameterized, _module, params} -> params
      _ -> nil
    end
  end

  defp pride(params) do
    params[:__pride__]
  end

  defp pride!(params) do
    case params[:__pride__] do
      nil ->
        error(params, "expected to find :__pride__ params")
        raise "schema was not compiled with uuidv7 support"

      pride_params ->
        pride_params
    end
  end

  def printable_encode(uuid) do
    Pride.Base62.UUID.encode_base62_uuid(uuid)
    # with {:ok, encoded} <- ExULID.Crockford.encode32(uuid), do: encoded
    # |> debug()
  end

  def printable_decode(uuid) do
    Pride.Base62.UUID.decode_base62_uuid(uuid)
    # with {:ok, decoded} <- ExULID.Crockford.decode32(uuid), do: decoded
    # |> debug()
  end
end
