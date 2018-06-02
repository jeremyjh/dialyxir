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
      {:ok, list} = :struct_parser.parse(tokens)
      List.first(list)
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
    pretty_print(rest)
  end

  def pretty_print_pattern(pattern) do
    pretty_print(pattern)
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
    |> Code.format_string!()
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
    |> Code.format_string!()
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
    |> Code.format_string!()
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
    struct_name = struct_name(map_keys)

    if struct_name do
      keys = Enum.reject(map_keys, &struct_name_entry?/1)

      "%#{struct_name}{#{Enum.map_join(keys, ", ", &do_pretty_print/1)}}"
    else
      "%{#{Enum.map_join(map_keys, ", ", &do_pretty_print/1)}}"
    end
  end

  defp do_pretty_print({:named_value, name, value}) do
    "#{do_pretty_print(name)} :: #{do_pretty_print(value)}"
  end

  defp do_pretty_print({:name, name}) do
    name
    |> remove_underscores()
    |> to_string()
  end

  defp do_pretty_print({nil}) do
    "nil"
  end

  defp do_pretty_print({:pattern, pattern_items}) do
    "<#{Enum.map_join(pattern_items, ", ", &do_pretty_print/1)}>"
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
    "#{remove_underscores(type)}()"
  end

  defp do_pretty_print({:type, module, type}) do
    "#{atomize(module)}.#{remove_underscores(type)}()"
  end

  defp do_pretty_print({:type, module, type, inner_type}) do
    "#{atomize(module)}.#{remove_underscores(type)}(#{do_pretty_print(inner_type)})"
  end

  defp do_pretty_print({:type_list, type, types}) do
    "#{remove_underscores(type)}#{do_pretty_print(types)}"
  end

  defp do_pretty_print({:variable_alias, variable_alias}) do
    variable_alias
    |> to_string()
    |> strip_var_version()
  end

  defp atomize('\'Elixir.\'' ++ module_name) do
    to_string(module_name)
  end

  defp atomize("Elixir." <> module_name) do
    "#{String.trim(module_name, "'")}"
  end

  defp atomize(atom) when is_list(atom) do
    atom
    |> remove_underscores()
    |> Enum.map(&atom_part_to_string/1)
    |> to_string()
    |> atomize()
  end

  defp atomize(<<atom>>) when is_number(atom) do
    "#{atom}"
  end

  defp atomize(atom) do
    atom =
      atom
      |> to_string()
      |> String.trim("'")

    inspect(:"#{atom}")
  end

  defp atom_part_to_string({:int, atom_part}), do: Integer.to_charlist(atom_part)
  defp atom_part_to_string(atom_part), do: atom_part

  defp strip_var_version(var_name) do
    String.replace(var_name, ~r/^V(.+)@\d+$/, "\\1")
  end

  defp struct_name(map_keys) do
    entry = Enum.find(map_keys, &struct_name_entry?/1)

    if entry do
      {:map_entry, _, {:atom, struct_name}} = entry

      struct_name
      |> atomize()
      |> String.trim("\"")
    end
  end

  defp remove_underscores(chars) do
    Enum.map(chars, fn char ->
      if is_atom(char) do
        Atom.to_string(char)
      else
        char
      end
    end)
  end

  defp struct_name_entry?({:map_entry, {:atom, '\'__struct__\''}, {:atom, _}}) do
    true
  end

  defp struct_name_entry?(_), do: false
end
