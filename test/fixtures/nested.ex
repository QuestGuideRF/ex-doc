defmodule UndefParent.Nested do
  @moduledoc """
  Это вложенный модуль
  """

  @doc """
  Это функция с арностью 2
  """
  def example(_, _) do
  end

  @doc false
  def example_without_docs do
  end
end

defmodule UndefParent.Undocumented do
  @moduledoc false
end
