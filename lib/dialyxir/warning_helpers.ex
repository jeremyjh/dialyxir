defmodule Dialyxir.WarningHelpers do
  @spec ordinal(non_neg_integer) :: String.t()
  def ordinal(1), do: "1st"
  def ordinal(2), do: "2nd"
  def ordinal(3), do: "3rd"
  def ordinal(n) when is_integer(n), do: "#{n}th"

  def call_or_apply_to_string(
        arg_positions,
        fail_reason,
        signature_args,
        signature_return,
        {overloaded?, contract}
      ) do
    pretty_contract = Dialyxir.PrettyPrint.pretty_print_contract(contract)
    pretty_signature_args = Dialyxir.PrettyPrint.pretty_print_args(signature_args)

    case fail_reason do
      :only_sig ->
        if Enum.empty?(arg_positions) do
          # We do not know which argument(s) caused the failure
          """
          will never return since the success typing arguments are
          #{pretty_signature_args}
          """
        else
          positions = form_position_string(arg_positions)

          """
          will never return since it differs in arguments with
          positions #{positions} from the success typing arguments:

          #{pretty_signature_args}
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
        pretty_print_signature =
          Dialyxir.PrettyPrint.pretty_print_contract("#{signature_args} -> #{signature_return}")

        """
        will never return since the success typing is:
        #{pretty_print_signature}

        and the contract is
        #{pretty_contract}
        """
    end
  end

  def form_position_string(arg_positions) do
    Enum.join(arg_positions, " and ")
  end
end
