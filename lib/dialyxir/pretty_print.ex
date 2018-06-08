defmodule Dialyxir.PrettyPrint do
  defp lex(str) do
    try do
      {:ok, tokens, _} = :struct_lexer.string(str)
      tokens
    rescue
      _ ->
        throw({:error, :lexing, str})
    end
  end

  defp parse(tokens) do
    try do
      {:ok, [first | _]} = :struct_parser.parse(tokens)
      first
    rescue
      _ ->
        throw({:error, :parsing, tokens})
    end
  end

  @spec pretty_print(String.t()) :: String.t()
  def pretty_print(str) do
    parsed =
      str
      |> to_charlist()
      |> lex()
      |> parse()

    try do
      do_pretty_print(parsed)
    rescue
      _ ->
        throw({:error, :pretty_printing, parsed})
    end
  end

  def pretty_print_pattern('pattern ' ++ rest) do
    pretty_print_type(rest)
  end

  def pretty_print_pattern(pattern) do
    pretty_print_type(pattern)
  end

  def pretty_print_contract(str, module, function) do
    multiple_heads? =
      str
      |> to_string()
      |> String.contains?(";")

    # TODO: This is kind of janky but I've only seen this once and am
    # not sure how to make it happen generally.
    if multiple_heads? do
      [head | tail] =
        str
        |> to_string()
        |> String.split(";")

      head =
        head
        |> String.trim_leading(to_string(module))
        |> String.trim_leading(":")
        |> String.trim_leading(to_string(function))

      joiner = "Contract head: "

      pretty =
        Enum.map_join([head | tail], joiner, fn str ->
          str
          |> to_charlist()
          |> pretty_print_contract()
        end)

      joiner <> pretty
    else
      pretty_print_contract(str)
    end
  end

  def pretty_print_contract(str) do
    prefix = "@spec a"
    suffix = "\ndef a() do\n  :ok\nend"
    pretty = pretty_print(str)

    """
    @spec a#{pretty}
    def a() do
      :ok
    end
    """
    |> format()
    |> Enum.join("")
    |> String.trim_leading(prefix)
    |> String.trim_trailing(suffix)
    |> String.replace("\n      ", "\n")
  end

  @spec pretty_print_type(String.t()) :: String.t()
  def pretty_print_type(str) do
    prefix = "@spec a("
    suffix = ") :: :ok\ndef a() do\n  :ok\nend"
    indented_suffix = ") ::\n        :ok\ndef a() do\n  :ok\nend"
    pretty = pretty_print(str)

    """
    @spec a(#{pretty}) :: :ok
    def a() do
      :ok
    end
    """
    |> format()
    |> Enum.join("")
    |> String.trim_leading(prefix)
    |> String.trim_trailing(suffix)
    |> String.trim_trailing(indented_suffix)
    |> String.replace("\n      ", "\n")
  end

  @spec pretty_print_args(String.t()) :: String.t()
  def pretty_print_args(str) do
    prefix = "@spec a"
    suffix = " :: :ok\ndef a() do\n  :ok\nend"
    pretty = pretty_print(str)

    """
    @spec a#{pretty} :: :ok
    def a() do
      :ok
    end
    """
    |> format()
    |> Enum.join("")
    |> String.trim_leading(prefix)
    |> String.trim_trailing(suffix)
    |> String.replace("\n      ", "\n")
  end

  defp do_pretty_print({:any}) do
    "_"
  end

  defp do_pretty_print({:any_function}) do
    "(... -> any)"
  end

  defp do_pretty_print({:assignment, name, value}) do
    "#{do_pretty_print(name)} = #{do_pretty_print(value)}"
  end

  defp do_pretty_print({:atom, [:_]}) do
    "_"
  end

  defp do_pretty_print({:atom, ['_']}) do
    "_"
  end

  defp do_pretty_print({:atom, atom}) do
    atomize(atom)
  end

  defp do_pretty_print({:binary_part, value, _, size}) do
    "#{do_pretty_print(value)} :: #{do_pretty_print(size)}"
  end

  defp do_pretty_print({:binary_part, value, size}) do
    "#{do_pretty_print(value)} :: #{do_pretty_print(size)}"
  end

  defp do_pretty_print({:binary, binary_parts}) do
    binary_parts = Enum.map_join(binary_parts, ", ", &do_pretty_print/1)
    "<<#{binary_parts}>>"
  end

  defp do_pretty_print({:binary, value, size}) do
    "<<#{do_pretty_print(value)} :: #{do_pretty_print(size)}>>"
  end

  defp do_pretty_print({:byte_list, byte_list}) do
    byte_list
    |> Enum.into(<<>>, fn byte ->
      <<byte::8>>
    end)
    |> inspect()
  end

  defp do_pretty_print({:contract, {:args, args}, {:return, return}}) do
    "#{do_pretty_print(args)} :: #{do_pretty_print(return)}"
  end

  defp do_pretty_print({:empty_list, :paren}) do
    "()"
  end

  defp do_pretty_print({:empty_list, :square}) do
    "[]"
  end

  defp do_pretty_print({:empty_map}) do
    "%{}"
  end

  defp do_pretty_print({:function, {:args, args}, {:return, return}}) do
    "(#{do_pretty_print(args)} -> #{do_pretty_print(return)})"
  end

  defp do_pretty_print({:int, int}) do
    "#{to_string(int)}"
  end

  defp do_pretty_print({:list, :paren, items}) do
    "(#{Enum.map_join(items, ", ", &do_pretty_print/1)})"
  end

  defp do_pretty_print({:list, :square, items}) do
    "[#{Enum.map_join(items, ", ", &do_pretty_print/1)}]"
  end

  defp do_pretty_print({:map_entry, key, value}) do
    "#{do_pretty_print(key)} => #{do_pretty_print(value)}"
  end

  defp do_pretty_print({:map, map_keys}) do
    %{struct_name: struct_name, entries: entries} = struct_parts(map_keys)

    if struct_name do
      "%#{struct_name}{#{Enum.map_join(entries, ", ", &do_pretty_print/1)}}"
    else
      "%{#{Enum.map_join(entries, ", ", &do_pretty_print/1)}}"
    end
  end

  defp do_pretty_print({:named_value, name, value}) do
    "#{do_pretty_print(name)} :: #{do_pretty_print(value)}"
  end

  defp do_pretty_print({:name, name}) do
    name
    |> deatomize()
    |> to_string()
    |> strip_var_version()
  end

  defp do_pretty_print({nil}) do
    "nil"
  end

  defp do_pretty_print({:pattern, pattern_items}) do
    "#{Enum.map_join(pattern_items, ", ", &do_pretty_print/1)}"
  end

  defp do_pretty_print({:pipe_list, head, tail}) do
    "#{do_pretty_print(head)} | #{do_pretty_print(tail)}"
  end

  defp do_pretty_print({:range, from, to}) do
    "#{from}..#{to}"
  end

  defp do_pretty_print({:rest}) do
    "..."
  end

  defp do_pretty_print({:size, size}) do
    "size(#{do_pretty_print(size)})"
  end

  defp do_pretty_print({:tuple, tuple_items}) do
    "{#{Enum.map_join(tuple_items, ", ", &do_pretty_print/1)}}"
  end

  defp do_pretty_print({:type, type}) do
    "#{deatomize(type)}()"
  end

  defp do_pretty_print({:type, module, type}) do
    module =
      if is_tuple(module) do
        do_pretty_print(module)
      else
        atomize(module)
      end

    type =
      if is_tuple(type) do
        do_pretty_print(type)
      else
        deatomize(type)
      end

    "#{module}.#{type}()"
  end

  defp do_pretty_print({:type, module, type, inner_type}) do
    "#{atomize(module)}.#{deatomize(type)}(#{do_pretty_print(inner_type)})"
  end

  defp do_pretty_print({:type_list, type, types}) do
    "#{deatomize(type)}#{do_pretty_print(types)}"
  end

  defp do_pretty_print({:variable_alias, variable_alias}) do
    variable_alias
    |> to_string()
    |> strip_var_version()
  end

  defp atomize("Elixir." <> module_name) do
    "#{String.trim(module_name, "'")}"
  end

  defp atomize(atom) when is_list(atom) do
    atom
    |> deatomize()
    |> to_string()
    |> strip_var_version()
    |> atomize()
  end

  defp atomize(<<atom>>) when is_number(atom) do
    "#{atom}"
  end

  defp atomize(atom) do
    atom = to_string(atom)

    if String.starts_with?(atom, "_") do
      atom
    else
      inspect(:"#{String.trim(atom, "'")}")
    end
  end

  defp atom_part_to_string({:int, atom_part}), do: Integer.to_charlist(atom_part)
  defp atom_part_to_string(atom_part), do: atom_part

  defp strip_var_version(var_name) do
    var_name
    |> String.replace(~r/^V(.+)@\d+$/, "\\1")
    |> String.replace(~r/^(.+)@\d+$/, "\\1")
  end

  defp struct_parts(map_keys) do
    %{struct_name: struct_name, entries: entries} =
      Enum.reduce(map_keys, %{struct_name: nil, entries: []}, &struct_part/2)

    %{struct_name: struct_name, entries: Enum.reverse(entries)}
  end

  defp struct_part({:map_entry, {:atom, '\'__struct__\''}, {:atom, struct_name}}, struct_parts) do
    struct_name =
      struct_name
      |> atomize()
      |> String.trim("\"")

    Map.put(struct_parts, :struct_name, struct_name)
  end

  defp struct_part(entry, struct_parts = %{entries: entries}) do
    Map.put(struct_parts, :entries, [entry | entries])
  end

  defp deatomize(chars) when is_list(chars) do
    Enum.map(chars, fn char ->
      char
      |> deatomize_char()
      |> atom_part_to_string()
    end)
  end

  defp deatomize_char(char) when is_atom(char) do
    Atom.to_string(char)
  end

  defp deatomize_char(char), do: char

  defp format(code) do
    try do
      Code.format_string!(code)
    rescue
      _ ->
        throw({:error, :formatting, code})
    end
  end
end
