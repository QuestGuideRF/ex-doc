defmodule CompiledWithDocs do
  @moduledoc """
  модульдок

  ## Пример ☃ Юникод > экранирование
      CompiledWithDocs.example

  ### Пример заголовка H3

  пример
  """

  @doc "Некоторая структура"
  defstruct [:field]

  @doc "Некоторые примеры"
  @doc purpose: :example
  @deprecated "Вместо этого используйте что-нибудь другое"
  def example(foo, bar \\ Baz), do: bar.baz(foo)

  @doc "Другой пример"
  @doc since: "1.3.0"
  defmacro example_1, do: 1

  @doc "Простой охранник"
  # TODO: удалить явную защиту: true, когда ~> 1.8
  defguard is_zero(number) when number == 0

  @doc """
  Делает пример действия.

  ### Примеры
  """
  @doc purpose: :example
  def example_with_h3, do: 1

  @deprecated "Вместо этого используйте что-нибудь другое"
  def example_without_docs, do: nil

  # Убедитесь, что делегат автоматически создает документы.
  defdelegate flatten(hello), to: List

  defmodule Nested do
  end
end
