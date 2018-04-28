defmodule Dialyxir.Formatter do
  @moduledoc """
  Elixir-friendly dialyzer formatter.

  Wrapper around normal Dialyzer warning messages that provides
  example output for error messages.
  """

  def formatted_time(duration_ms) do
    minutes = div(duration_ms, 6_000_000)
    seconds = rem(duration_ms, 6_000_000) / 1_000_000 |> Float.round(2)
    "done in #{minutes}m#{seconds}s"
  end

  def format_and_filter(warnings, filterer, format) when format in [:dialyzer, :dialyxir] do
    divider = String.duplicate("_", 80)
    warnings
    |> Enum.map(fn warning ->
      message =
        try do
          format_warning(warning, format)
        catch
          {:error, :message, warning} ->
            """
            Please file a bug in https://github.com/jeremyjh/dialyxir/pull/118 with this message.

            Failed to parse warning:
            #{inspect(warning)}

            Legacy warning:
            #{format_warning(warning, :dialyzer)}
            """

          {:error, :parsing, failing_string} ->
            """
            Please file a bug in https://github.com/jeremyjh/dialyxir/pull/118 with this message.

            Failed to parse part of warning:
            #{inspect(warning)}

            Failing part:
            #{failing_string}

            Legacy warning:
            #{format_warning(warning, :dialyzer)}
            """
        end
      message <> divider
    end)
    |> filterer.filter_warnings()
  end

  def format_and_filter(warnings, _, :raw) do
    Enum.map(warnings, &inspect/1)
  end

  defp format_warning(warning, :dialyzer) do
    warning
    |> :dialyzer.format_warning(:fullpath)
    |> String.Chars.to_string()
    |> String.replace_trailing("\n", "")
  end

  defp format_warning({_tag, {file, line}, message}, :dialyxir) do
    base_name = Path.relative_to_cwd(file)
    string = message_to_string(message)

    """
    #{base_name}:#{line}
    #{string}
    """
  end

  # Warnings for general discrepancies

  defp message_to_string({:apply, [args, arg_positions, fail_reason, signature_args, signature_return, contract]}) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)
    "Fun application with arguments #{pretty_args} #{call_or_apply_to_string(arg_positions, fail_reason, signature_args, signature_return, contract)}."
  end

  defp message_to_string({:app_call, [module, function, args, culprit, expected_type, actual_type]}) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "The call #{pretty_module}.#{function}#{pretty_args} requires that #{culprit} is of type #{expected_type} not #{actual_type}."
  end

  defp message_to_string({:bin_construction, [culprit, size, segment, type]}) do
    "Binary construction will fail since the #{culprit} field #{size} in segment #{segment} has type #{type}."
  end

  defp message_to_string({:call, [module, function, args, arg_positions, fail_reason, signature_args, signature_return, contract]}) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "The call #{pretty_module}.#{function}#{pretty_args} #{call_or_apply_to_string(arg_positions, fail_reason, signature_args, signature_return, contract)}."
  end

  defp message_to_string({:call_to_missing, [module, function, arity]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "Call to missing or private function #{pretty_module}.#{function}/#{arity}."
  end

  defp message_to_string({:callback_type_mismatch, [module, function, arity, fail_type, success_type]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_fail_type = Dialyxir.PrettyPrint.pretty_print(fail_type)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_contract(success_type)

    """
    Callback mismatch for @callback #{pretty_module}.#{function}/#{arity}.

    Expecred type:
    #{pretty_success_type}

    Actual type:
    #{pretty_fail_type}
    """
  end

  defp message_to_string({:exact_eq, [type1, op, type2]}) do
    "The test #{type1} #{op} #{type2} can never evaluate to 'true'."
  end

  defp message_to_string({:fun_app_args, [args, type]}) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)
    "Fun application with arguments #{pretty_args} will fail since the function has type #{type}."
  end

  defp message_to_string({:fun_app_no_fun, [op, type, arity]}) do
    "Fun application will fail since #{op} :: #{type} is not a function of arity #{arity}."
  end

  defp message_to_string({:guard_fail, []}) do
    "Clause guard cannot succeed."
  end

  defp message_to_string({:guard_fail, [arg1, infix, arg2]}) do
    "Guard test #{arg1} #{infix} #{arg2} can never succeed."
  end

  defp message_to_string({:guard_fail, [guard, args]}) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)

    """
    Guard test:
    #{guard}#{pretty_args}

    can never succeed.
    """
  end

  defp message_to_string({:guard_fail_pat, [pattern, type]}) do
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)
    pretty_pattern = Dialyxir.PrettyPrint.pretty_print_pattern(pattern)
    "Clause guard cannot succeed. The pattern #{pretty_pattern} was matched against the type #{pretty_type}."
  end

  defp message_to_string({:improper_list_constr, [tl_type]}) do
    pretty_type = Dialyxir.PrettyPrint.pretty_print(tl_type)
    "Cons will produce an improper list since its 2nd argument is #{pretty_type}."
  end

  defp message_to_string({:neg_guard_fail, [arg1, infix, arg2]}) do
    """
    Guard test:
    not #{arg1} #{infix} #{arg2}

    can never succeed.
    """
  end

  defp message_to_string({:neg_guard_fail, [guard, args]}) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)

    """
    Guard test:
    not #{guard}#{pretty_args}

    can never succeed.
    """
  end

  defp message_to_string({:no_return, [type | name]}) do
    name_string =
      case name do
        [] ->
          "The created fun "
        [function, arity] ->
          "Function #{function}/#{arity} "
      end

    type_string =
      case type do
        :no_match ->
          "has no clauses that will ever match."
        :only_explicit ->
          "only terminates with explicit exception."
        :only_normal ->
          "has no local return."
        :both ->
          "has no local return."
      end

    name_string <> type_string
  end

  defp message_to_string({:pattern_match, [pattern, type]}) do
    pretty_pattern = Dialyxir.PrettyPrint.pretty_print_pattern(pattern)
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)
    "The #{pretty_pattern} can never match the type #{pretty_type}."
  end

  defp message_to_string({:pattern_match_cov, [pattern, type]}) do
    pretty_pattern = Dialyxir.PrettyPrint.pretty_print_pattern(pattern)
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)
    "The #{pretty_pattern} can never match since previous clauses completely covered the type #{pretty_type}."
  end

  defp message_to_string({:unknown_behaviour, behaviour}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(behaviour)

    "Unknown behaviour: #{pretty_module}."
  end

  defp message_to_string({:unknown_function, {module, function, arity}}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "Function #{pretty_module}.#{function}/#{arity} does not exist."
  end

  defp message_to_string({:unknown_type, {module, function, arity}}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)

    "Unknown type: #{pretty_module}.#{function}/#{arity}."
  end

  defp message_to_string({:unmatched_return, [type]}) do
    pretty_type = Dialyxir.PrettyPrint.pretty_print_type(type)
    """
    Expression produces a value of type:

    #{pretty_type}

    but this value is unmatched.
    """
  end

  defp message_to_string({:unused_fun, []}) do
    "Function will never be called."
  end

  defp message_to_string({:unused_fun, [function, arity]}) do
    "Function #{function}/#{arity} will never be called."
  end

  # Warnings for specs and contracts

  defp message_to_string({:contract_diff, [module, function, arity, contract, signature]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_contract = Dialyxir.PrettyPrint.pretty_print_type(contract)

    """
    Type specification is not equal to the success typing.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Type specification:
    #{pretty_contract}

    Success typing:
    #{signature}

    This happens when either the function is not returning the proper
    value, or the `@spec` is incorrect.
    """
  end

  defp message_to_string({:contract_subtype, [module, function, arity, contract, signature]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_contract = Dialyxir.PrettyPrint.pretty_print_contract(contract)

    """
    Type specification is a subtype of the success typing.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Type specification:
    @spec #{function}#{pretty_contract}

    Success typing:
    #{signature}
    """
  end

  defp message_to_string({:contract_supertype, [module, function, arity, contract, signature]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    pretty_contract = Dialyxir.PrettyPrint.pretty_print_contract(contract)

    """
    Type specification is a supertype of the success typing.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Type specification:
    @spec #{function}#{pretty_contract}

    Success typing:
    #{signature}
    """
  end

  defp message_to_string({:invalid_contract, [module, function, arity, signature]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)

    """
    Invalid type specification for function.

    Function:
    #{pretty_module}.#{function}/#{arity}

    Success typing:
    #{signature}
    """
  end

  defp message_to_string({:extra_range, [module, function, arity, extra_ranges, signature_range]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "The specification for #{pretty_module}.#{function}/#{arity} states that the function might also return #{extra_ranges} but the inferred return is #{signature_range}."
  end

  defp message_to_string({:overlapping_contract, [module, function, arity]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    """
    Overloaded contract for #{pretty_module}.#{function}/#{arity} has overlapping domains;
    such contracts are currently unsupported and are simply ignored.
    """
  end

  defp message_to_string({:spec_missing_fun, [module, function, arity]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "Contract for function that does not exist: #{pretty_module}.#{function}/#{arity}."
  end

  # Warnings for opaque type violations

  defp message_to_string({:call_with_opaque, [module, function, args, arg_positions, expected_args]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "The call #{pretty_module}.#{function}#{args} contains #{form_positions(arg_positions)} when #{form_expected(expected_args)}}."
  end

  defp message_to_string({:call_without_opaque, [module, function, args, expected_triples]}) do
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)
    "The call #{pretty_module}.#{function}#{args} does not have #{form_expected_without_opaque(expected_triples)}."
  end

  defp message_to_string({:opaque_eq, [type, _op, opaque_type]}) do
    "Attempt to test for equality between a term of type #{type} and a term of opaque type #{opaque_type}."
  end

  defp message_to_string({:opaque_guard, [guard, args]}) do
    "Guard test #{guard}#{args} breaks the opaqueness of its argument."
  end

  defp message_to_string({:opaque_match, [pattern, opaque_type, opaque_term]}) do
    term =
      if opaque_type == opaque_term do
        "the term"
      else
        opaque_term
      end
    pretty_pattern = Dialyxir.PrettyPrint.pretty_print_pattern(pattern)

    "The attempt to match a term of type #{opaque_term} against the #{pretty_pattern} breaks the opaqueness of #{term}."
  end

  defp message_to_string({:opaque_neq, [type, _op, opaque_type]}) do
    "Attempt to test for inequality between a term of type #{type} and a term of opaque type #{opaque_type}."
  end

  defp message_to_string({:opaque_type_test, [function, opaque]}) do
    "The type test #{function}(#{opaque}) breaks the opaqueness of the term #{opaque}."
  end

  # Warnings for concurrency errors

  defp message_to_string({:race_condition, [module, function, args, reason]}) do
    pretty_args = Dialyxir.PrettyPrint.pretty_print_args(args)
    pretty_module = Dialyxir.PrettyPrint.pretty_print(module)

    "The call #{pretty_module},#{function}#{pretty_args} #{reason}."
  end

  # Erlang patterns

  defp message_to_string({:record_constr, [types, name]}) do
    "Record construction #{types} violates the declared type for ##{name}{}."
  end

  defp message_to_string({:record_constr, [name, field, type]}) do
    "Record construction violates the declared type for ##{name}{} since #{field} cannot be of type #{type}."
  end

  defp message_to_string({:record_matching, [string, name]}) do
    "The #{string} violates the declared type for ##{name}{}."
  end

  defp message_to_string({:callback_arg_type_mismatch, [behaviour, function, arity, success_type, callback_type]}) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_type(success_type)
    pretty_callback_type = Dialyxir.PrettyPrint.pretty_print_type(callback_type)

    """
    The inferred return type of #{function}/#{arity}
    (#{pretty_success_type}) has nothing in common
    with #{pretty_callback_type}, which is the expected return type
    for the callback of the #{pretty_behaviour} behaviour.
    """
  end

  defp message_to_string({:callback_arg_type_mismatch, [behaviour, function, arity, position, success_type, callback_type]}) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_type(success_type)
    pretty_callback_type = Dialyxir.PrettyPrint.pretty_print_type(callback_type)

    """
    The inferred type for the #{ordinal(position)} argument
    of #{function}/#{arity} (#{pretty_success_type})) is not a supertype of
    #{pretty_callback_type}, which is expected type for this argument
    in the callback of the #{pretty_behaviour} behaviour.
    """
  end

  defp message_to_string({:callback_spec_type_mismatch, [behaviour, function, arity, success_type, callback_type]}) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_type(success_type)
    pretty_callback_type = Dialyxir.PrettyPrint.pretty_print_type(callback_type)

    """
    The return type #{pretty_success_type} in the specification
    of #{function}/#{arity} is not subtype of #{pretty_callback_type},
    which is the expected return type for the callback of
    the #{pretty_behaviour} behaviour.
    """
  end

  defp message_to_string({:callback_spec_arg_type_mismatch, [behaviour, function, arity, position, success_type, callback_type]}) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)
    pretty_success_type = Dialyxir.PrettyPrint.pretty_print_type(success_type)
    pretty_callback_type = Dialyxir.PrettyPrint.pretty_print_type(callback_type)

    """
    The specified type for the #{ordinal(position)} argument
    of #{function}/#{arity} (#{pretty_success_type}) is not a supertype
    of #{pretty_callback_type}, which is the expected type for this
    argment in the callback of the #{pretty_behaviour} behaviour.
    """
  end

  defp message_to_string({:callback_missing, [function, arity, behaviour]}) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)

    "Undefined callback function #{function}/#{arity} (behaviour #{pretty_behaviour})."
  end

  defp message_to_string({:callback_info_missing, [behaviour]}) do
    pretty_behaviour = Dialyxir.PrettyPrint.pretty_print(behaviour)

    "Callback info about the #{pretty_behaviour} behaviour is not available."
  end

  defp message_to_string(message) do
    throw {:error, :message, message}
  end

  defp call_or_apply_to_string(arg_positions, fail_reason, signature_args, signature_return, {overloaded?, contract}) do
    pretty_contract = Dialyxir.PrettyPrint.pretty_print_contract(contract)
    case fail_reason do
      :only_sig ->
        if Enum.empty?(arg_positions) do
	  # We do not know which argument(s) caused the failure
	  "will never return since the success typing arguments are #{signature_args}"
        else
          position_string = form_position_string(arg_positions)
	  """
          will never return since it differs in argument:
          #{position_string}

          from the success typing arguments:
          #{signature_args}
          """
        end
      :only_contract ->
        if Enum.empty?(arg_positions) or overloaded? do
	  # We do not know which arguments caused the failure
	  """
          breaks the contract
          #{pretty_contract}
          """
        else
          position_string = form_position_string(arg_positions)
	  """
          breaks the contract
          #{pretty_contract}

          in argument
          #{position_string}
          """
        end
      :both ->
        """
        will never return since the success typing is:
        #{signature_args} -> #{signature_return}

        and the contract is
        #{pretty_contract}
        """
    end
  end

  defp form_positions(arg_positions = [_]) do
    form_position_string = form_position_string(arg_positions)
    "an opaque term in #{form_position_string} argument"
  end

  defp form_positions(arg_positions) do
    form_position_string = form_position_string(arg_positions)
    "opaque terms in #{form_position_string} arguments"
  end

  # We know which positions N are to blame;
  # the list of triples will never be empty.
  defp form_expected_without_opaque([{position, type, type_string}]) do
    form_position_string = form_position_string([position])
    message =
      if :erl_types.t_is_opaque(type) do
        "an opaque term of type #{type_string} in "
      else
        "a term of type #{type_string} (with opaque subterms) in "
      end

    message <> form_position_string
  end

  defp form_expected_without_opaque(expected_triples) do # TODO: can do much better here
    {arg_positions, _typess, _type_strings} = :lists.unzip3(expected_triples)
    form_position_string = form_position_string(arg_positions)
    "opaque terms in #{form_position_string}"
  end

  defp form_expected([type]) do
    type_string = :erl_types.t_to_string(type)
    if :erl_types.t_is_opaque(type) do
      "an opaque term of type #{type_string} is expected"
    else
      "a structured term of type #{type_string} is expected"
    end
  end

  defp form_expected(_expected_args) do
    "terms of different types are expected in these positions"
  end

  defp form_position_string([]), do: ""
  defp form_position_string(arg_positions) do
    arg_string = Enum.join(arg_positions, " and ")
    "positions #{arg_string}"
  end

  @spec ordinal(non_neg_integer) :: String.t()
  defp ordinal(1), do: "1st"
  defp ordinal(2), do: "2nd"
  defp ordinal(3), do: "3rd"
  defp ordinal(n) when is_integer(n), do: "#{n}th"
end
