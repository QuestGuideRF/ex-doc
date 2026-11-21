defmodule ExDoc.Markdown do
  @moduledoc """
  Adapter behaviour and conveniences for converting Markdown to HTML.

  ExDoc is compatible with any markdown processor that implements the
  functions defined in this module. The markdown processor can be changed
  via the `:markdown_processor` option in your `mix.exs`.

  ExDoc supports the following Markdown parsers out of the box:

    * [Earmark](http://github.com/pragdave/earmark)
    * [Cmark](https://github.com/asaaki/cmark.ex)

  ExDoc uses Earmark by default.

  ### Using cmark

  [Cmark](https://github.com/jgm/cmark) is a CommonMark parser written in C.
  To use cmark, add the Elixir NIF wrapper [cmark.ex](https://github.com/asaaki/cmark.ex)
  as a dependency to your project:

      {:cmark, "~> 0.6", only: :dev}

  And then update your project configuration to use Cmark:

      docs: [markdown_processor: ExDoc.Markdown.Cmark]

  """

  @doc """
  Преобразует уценку в HTML.
  """
  @callback to_html(String.t(), Keyword.t()) :: String.t()

  @doc """
  Assets specific to the markdown implementation.

  This callback takes the documentation format (`:html` or `:epub`) as an argument
  and must return a list of pairs of the form `{basename, content}` where:

    * `basename` - relative path that will be written inside the `doc/` directory.
    * `content` - is a binary with the full contents of the file that will be written to `basename`.

  ## EPUB Documentation Gotchas

  Generating HTML documentation is simple, and it works exacly as you would expect
  for a webpage. The EPUB file format, on the other hand, may cause some surprise.

  Apparently, an EPUB file expects all assets to have a unique name *when
  discarding the file extension*.

  This creates problems if you include, for example, the files `custom.js`
  and `custom.css`. Because the filename without the extension is equal (`custom`),
  you will get an unreadable EPUB. It's possible to go around this limitation by simply
  giving the files unique names:

    * `custom.js` becomes `custom-js.js` *and*
    * `custom.css` becomes `custom-css.css`

  ## Example

      def callback assets(_) do
        [{"dist/custom-css.css", custom_css_content()},
         {"dist/custom-js.js", custom_js_content()}]
      конец

  """
  @callback assets(atom) :: [{String.t(), String.t()}]

  @doc """
  Literal content to be written to the file just before the closing head tag.

  This callback takes the documentation format (`:html` or `:epub`) as an argument
  and returns a literal string. It is useful when the markdown processor needs to
  a include extra CSS.

  ## Example

      def callback before_closing_head_tag(_) do
        # Include the CSS specified in the assets/1 callback
        ~S(<link rel="stylesheet" href="dist/custom-css.css"/>)
      end

  """
  @callback before_closing_head_tag(atom) :: String.t()

  @doc """
  Literal content to be written to the file just before the closing body tag.

  This callback takes the documentation format (`:html` or `:epub`) as an argument
  and returns a literal string. It is useful when the markdown processor needs to
  a include extra JavaScript.

  ## Example

      def callback before_closing_body_tag(_) do
        # Include the Javascript specified in the assets/1 callback
        ~S(<script src="dist/custom-js.js"></скрипт>)
      конец

  """
  @callback before_closing_body_tag(atom) :: String.t()

  @doc """
  Функция, которая принимает параметры конфигурации и настраивает процессор уценки.

  Он запускается один раз при загрузке `:ex_doc`, а возвращаемое значение отбрасывается.
  Модули, реализующие такое поведение, вероятно, где-то сохранят параметры.
  чтобы к ним можно было получить доступ при необходимости.

  Формат опций, а также то, что функция делает с ними:
  полностью зависит от модуля, который реализует поведение.
  """
  @callback configure(any) :: :ok

  @markdown_processors [
    ExDoc.Markdown.Earmark,
    ExDoc.Markdown.Cmark
  ]

  @markdown_processor_key :markdown_processor

  @doc """
  Преобразует данный документ уценки в HTML.
  """
  def to_html(text, opts \\ []) when is_binary(text) do
    get_markdown_processor().to_html(text, opts)
  end

  @doc """
  Получает текущий глобальный процессор уценки.
  """
  def get_markdown_processor do
    case Application.fetch_env(:ex_doc, @markdown_processor_key) do
      {:ok, processor} ->
        processor

      :error ->
        processor = find_markdown_processor() || raise_no_markdown_processor()
        put_markdown_processor(processor)
        processor
    end
  end

  @doc """
  Изменяет процессор уценки глобально.
  """
  def put_markdown_processor(processor) do
    Application.put_env(:ex_doc, @markdown_processor_key, processor)
  end

  @doc false
  def configure_processor(options) do
    # Эта функция настраивает процессор уценки с заданными параметрами.
    # Он вызывается ровно один раз, когда ExDoc считывает свои собственные параметры конфигурации.
    # Предполагается, что его назвали из-за его побочных эффектов.
    get_markdown_processor().configure(options)
  end

  defp find_markdown_processor do
    Enum.find(@markdown_processors, fn module ->
      Code.ensure_loaded?(module) && module.available?
    end)
  end

  defp raise_no_markdown_processor do
    raise """
    Could not find a markdown processor to be used by ex_doc.
    You can either:

    * Add {:earmark, ">= 0.0.0"} в ваши описания mix.exs
      использовать процессор уценки на основе Elixir

    * Добавьте {:cmark, ">= 0.5"} в ваши описания mix.exs
      использовать другой процессор уценки на базе C
    """
  end
end
