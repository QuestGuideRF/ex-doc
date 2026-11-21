defmodule ExDoc.Markdown.Cmark do
  @moduledoc """
  Расширение ExDoc для парсера Cmark Markdown.
  """
  @behaviour ExDoc.Markdown

  # Реализации обратного вызова
  def assets(arg), do: ExDoc.Highlighter.assets(arg)

  def before_closing_head_tag(arg), do: ExDoc.Highlighter.before_closing_head_tag(arg)

  def before_closing_body_tag(arg), do: ExDoc.Highlighter.before_closing_body_tag(arg)

  def configure(_), do: :ok

  @doc """
  Проверьте, доступен ли модуль парсера Cmark Markdown.
  """
  def available? do
    Code.ensure_loaded?(Cmark)
  end

  @doc """
  Сгенерируйте вывод HTML.

  ## Опции

    * `:highlight_tag` — тег, используемый для подсветки кода, по умолчанию "span"
  """
  def to_html(text, opts) do
    text
    |> Cmark.to_html()
    |> ExDoc.Highlighter.highlight_code_blocks(opts)
  end
end
