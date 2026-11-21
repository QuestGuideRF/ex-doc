defmodule Warnings do
  @moduledoc """
  `Предупреждения.бар/0`
  """

  @typedoc """
  `Предупреждения.бар/0`
  """
  @type t() :: :ok

  @doc """
  `Предупреждения.бар/0`
  """
  @callback handle_foo() :: :ok

  @doc """
  `Предупреждения.бар/0`
  """
  def foo(), do: :ok
end
