defmodule CustomBehaviourOne do
  # Даже если мы определим структуру, этот модуль все равно должен быть указан как поведение.
  defstruct [:a, :b]

  @doc """
  Это пример обратного вызова.
  """
  @callback hello(%URI{}) :: integer
  @callback greet(integer | String.t()) :: integer
end

defmodule CustomBehaviourTwo do
  @doc """
  Это другой пример обратного вызова.
  """
  @macrocallback bye(integer) :: integer
end

defmodule CustomBehaviourImpl do
  @behaviour CustomBehaviourOne
  @behaviour CustomBehaviourTwo

  def hello(i), do: i
  def greet(i), do: i

  @doc "Документ для этого, чтобы он не использовал «Реализацию обратного вызова для»"
  defmacro bye(i), do: i
end
