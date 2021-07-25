defmodule Magpie.Helpers do
  @moduledoc """
  Helper functions for the contexts
  """

  # This special processing has always been there and let's keep it this way.
  def format_value(value) when is_list(value) do
    Enum.join(value, "|")
  end

  def format_value(value) do
    case String.Chars.impl_for(value) do
      # e.g. maps. Then we just return it as it is.
      nil ->
        Kernel.inspect(value)

      _ ->
        to_string(value)
    end
  end
end
