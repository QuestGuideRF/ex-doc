defmodule TypesAndSpecs do
  defmodule Sub do
    @type t :: any
  end

  @moduledoc """
  Виды и испытания приспособления.

  Базовый тип: `t:atom/0`.
  Специальная форма: `импорт/2`.
  """

  @typedoc "Публичный тип"
  @type public(t) :: {t, String.t(), Sub.t(), opaque, :ok | :error}
  @typep private :: any
  @opaque opaque :: {Dict.t()}
  @type ref :: {:binary.part(), public(any)}
  @typedoc false
  @type internal :: any

  @spec add(integer, opaque) :: integer
  def add(x, _), do: x + x

  @spec minus(integer, integer) :: integer
  defp minus(x, y), do: x - y

  @spec macro_spec(any) :: {:ok, any}
  defmacro macro_spec(v), do: {:ok, v}

  @spec priv_macro_spec(any) :: {:no, any}
  defmacrop priv_macro_spec(v), do: {:no, v}

  # Это просто для того, чтобы игнорировать предупреждения о неиспользуемых частных типах/функциях.
  @spec ignore(private) :: integer
  def ignore(_), do: priv_macro_spec(minus(0, 0))
end
