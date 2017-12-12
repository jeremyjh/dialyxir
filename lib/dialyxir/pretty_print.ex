defmodule Dialyzir.PrettyPrint do

  defp parse(str) do
    {:ok, tokens, _} = str |> to_charlist() |> :struct_lexer.string()
    {:ok, list} = :struct_parser.parse(tokens)
    list
  end

  def pretty_print(str) do
    str
    |> parse()
    |> List.first()
    |> do_pretty_print()
    |> IO.puts()
  end

  defp do_pretty_print({:function, {:args, args}, {:return, return}}) do
    "(#{do_pretty_print(args)} -> #{do_pretty_print(return)})"
  end

  defp do_pretty_print({:list, :paren, items}) do
    "(#{Enum.map_join(items, ", ", &do_pretty_print/1)})"
  end

  defp do_pretty_print({:list, :square, items}) do
    "[#{Enum.map_join(items, ", ", &do_pretty_print/1)}]"
  end

  defp do_pretty_print({:pipe_list, head, tail}) do
    "#{do_pretty_print(head)} | #{do_pretty_print(tail)}"
  end

  defp do_pretty_print({:type_list, type, types}) do
    "#{type}#{do_pretty_print(types)}"
  end

  defp do_pretty_print({:int, int}) do
    "#{int}"
  end

  defp do_pretty_print({:empty_list, :square}) do
    "[]"
  end

  defp do_pretty_print({:type, type}) do
    "#{type}()"
  end

  defp do_pretty_print({:tuple, tuple_items}) do
    "{#{Enum.map_join(tuple_items, ", ", &do_pretty_print/1)}}"
  end

  defp do_pretty_print({:atom, atom}) do
    module_name = strip_elixir(atom)
    if module_name == to_string(atom) do
      ":#{atom}"
    else
      "#{module_name}"
    end
  end

  defp do_pretty_print({:any}) do
    "any()"
  end

  defp do_pretty_print({:nil}) do
    "nil"
  end

  defp do_pretty_print({:empty_map}) do
    "%{}"
  end

  defp do_pretty_print({:map, map_keys}) do
    struct_name = struct_name(map_keys)
    if struct_name do
      keys = Enum.reject(map_keys, &struct_name_entry?/1)

      "%#{struct_name}{#{Enum.map_join(keys, ",", &do_pretty_print/1)}}"
    else
      "%{#{Enum.map_join(map_keys, ", ", &do_pretty_print/1)}}"
    end
  end

  defp do_pretty_print({:map_entry, key, value}) do
    "#{do_pretty_print(key)} => #{do_pretty_print(value)}"
  end

  defp strip_elixir(string) do
    string
    |> to_string()
    |> String.trim("Elixir.")
  end

  defp struct_name(map_keys) do
    entry = Enum.find(map_keys, &struct_name_entry?/1)

    if entry do
      {:map_entry, _, {:atom, struct_name}} = entry
      strip_elixir(struct_name)
    end
  end

  defp struct_name_entry?({:map_entry, {:atom, '__struct__'}, _value}), do: true
  defp struct_name_entry?(_), do: false
end

str1 = ~S"""
(#{
'__struct__':='Elixir.Plug.Conn',
'adapter':={atom(),_},
'assigns':=#{atom()=>_},
'before_send':=[
  fun(
    (
      #{
        '__struct__':='Elixir.Plug.Conn',
        'adapter':={_,_}, '
        assigns':=map(),
        'before_send':=[
          fun((_) -> any())], _=>_}) -> #{'__struct__':='Elixir.Plug.Conn', 'adapter':={_,_}, 'assigns':=map(),
'before_send':=[fun((_) -> any())], _=>_})],
'body_params':=#{'__struct__'=>'Elixir.Plug.Conn.Unfetched', 'aspect'=>atom(), binary()=>binary() | [binary() | [any()] | #{binary()=>_}] | #{binary()=>binary() | [any()] | #{binary()=>_}}},
'cookies':=#{'__struct__'=>'Elixir.Plug.Conn.Unfetched',
'aspect'=>atom(),
binary()=>binary()},
'halted':=_,
'host':=binary(),
'method':=binary(),
'owner':=pid(),
'params':=#{
  '__struct__'=>'Elixir.Plug.Conn.Unfetched',
  'aspect'=>atom(),
  binary()=>binary() | [binary() | [any()] | #{binary()=>_}] | #{binary()=>binary() | [any()] | #{binary()=>_}}
},
'path_info':=[binary()],
'path_params':=#{binary()=>binary() | [binary() | [any()] | #{binary()=>_}] | #{binary()=>binary() | [any()] | #{binary()=>_}}},
'peer':={{byte(),byte(),byte(),byte()} | {char(),char(),char(),char(),char(),char(),char(),char()},char()},
'port':=char(),
'private':=#{atom()=>_},
'query_params':=#{'__struct__'=>'Elixir.Plug.Conn.Unfetched', 'aspect'=>atom(), binary()=>binary() | [binary() | [any()] | #{binary()=>_}] | #{binary()=>binary() | [any()] | #{binary()=>_}}},
'query_string':=binary(),
'remote_ip':={byte(),byte(),byte(),byte()} | {char(),char(),char(),char(),char(),char(),char(),char()},
'req_cookies':=#{'__struct__'=>'Elixir.Plug.Conn.Unfetched', 'aspect'=>atom(), binary()=>binary()},
'req_headers':=[{binary(),binary()}],
'request_path':=binary(),
'resp_body':='nil' | binary() | maybe_improper_list(binary() | maybe_improper_list(any(),binary() | []) | byte(),binary() | []),
'resp_cookies':=#{binary()=>#{}}, 'resp_headers':=[{binary(),binary()}],
'scheme':='http' | 'https',
'script_name':=[binary()],
'secret_key_base':='nil' | binary(), 'state':='chunked' | 'file' | 'sent' | 'set' | 'set_chunked' | 'set_file' | 'unset',
'status':='nil' | 1..1114111},'Elixir.Hello13Web.ErrorView','404')
"""

Dialyzir.PrettyPrint.pretty_print(str1)
