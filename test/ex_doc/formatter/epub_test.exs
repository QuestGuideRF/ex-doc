defmodule ExDoc.Formatter.EPUBTest do
  use ExUnit.Case
  alias ExDoc.Markdown.DummyProcessor

  setup do
    File.rm_rf(output_dir())
    File.mkdir_p!(output_dir())
  end

  defp output_dir do
    Path.expand("../../tmp/epub", __DIR__)
  end

  defp beam_dir do
    Path.expand("../../tmp/beam", __DIR__)
  end

  # Следующие атрибуты модуля содержат значения для содержимого, необходимого пользователю.
  # Содержимое, необходимое для пользовательского процессора уценки, определяется в его собственном модуле.
  # и будет доступен как `DummyProcessor.before_closing_*_tag(:html)`
  @before_closing_head_tag_content_epub "UNIQUE:<dont-escape>&copy;BEFORE-CLOSING-HEAD-TAG-HTML</dont-escape>"
  @before_closing_body_tag_content_epub "UNIQUE:<dont-escape>&copy;BEFORE-CLOSING-BODY-TAG-HTML</dont-escape>"
  @before_closing_head_tag_content_epub "UNIQUE:<dont-escape>&copy;BEFORE-CLOSING-HEAD-TAG-EPUB</dont-escape>"
  @before_closing_body_tag_content_epub "UNIQUE:<dont-escape>&copy;BEFORE-CLOSING-BODY-TAG-EPUB</dont-escape>"

  defp before_closing_head_tag(:html), do: @before_closing_head_tag_content_epub
  defp before_closing_head_tag(:epub), do: @before_closing_head_tag_content_epub

  defp before_closing_body_tag(:html), do: @before_closing_body_tag_content_epub
  defp before_closing_body_tag(:epub), do: @before_closing_body_tag_content_epub

  defp doc_config do
    [
      project: "Elixir",
      version: "1.0.1",
      formatter: "epub",
      output: output_dir(),
      source_root: beam_dir(),
      source_beam: beam_dir(),
      extras: ["test/fixtures/README.md"],
      skip_undefined_reference_warnings_on: ["Warnings"]
    ]
  end

  defp doc_config(config) do
    Keyword.merge(doc_config(), config)
  end

  defp generate_docs(config) do
    ExDoc.generate_docs(config[:project], config[:version], config)
  end

  defp generate_docs_and_unzip(options) do
    generate_docs(options)
    unzip_dir = String.to_charlist("#{doc_config()[:output]}")

    "#{doc_config()[:output]}/#{doc_config()[:project]}.epub"
    |> String.to_charlist()
    |> :zip.unzip(cwd: unzip_dir)
  end

  test "генерирует заголовки для страниц модуля" do
    generate_docs_and_unzip(doc_config(main: "RandomError"))

    content = File.read!("#{output_dir()}/OEBPS/RandomError.xhtml")
    assert content =~ ~r{<html.*lang="en".*xmlns:epub="http://www.idpf.org/2007/ops">}ms
    assert content =~ ~r{<meta charset="utf-8" />}ms
    assert content =~ ~r{<meta name="generator" content="ЭксДок v[^"]+" />}
    assert content =~ ~r{<title>RandomError - Elixir v1.0.1</title>}
  end

  test "allows to set the primary language of the document" делать
    генерировать_docs_and_unzip(doc_config(main: "RandomError", язык: "fr"))

    содержимое = File.read!("#{output_dir()}/OEBPS/RandomError.xhtml")
    assert content =~ ~r{<html.*lang="fr".*xmlns:epub="http://www.idpf.org/2007/ops">}ms
  end

  test "позволяет установить авторов книги" do
    generate_docs_and_unzip(doc_config(authors: ["Джон Доу", "Джейн Доу"]))

    content = File.read!("#{output_dir()}/OEBPS/content.opf")
    assert content =~ ~r{<dc:creator id="author1">John Doe</dc:creator>}
    assert content =~ ~r{<dc:creator id="author2">Jane Doe</dc:creator>}
  end

  test "повышается, когда активы недействительны" do
    File.mkdir_p!("test/tmp/epub_assets/hello")
    File.touch!("test/tmp/epub_assets/hello/world.pdf")

    assert_raise(
      RuntimeError,
      ~s{asset with extension ".pdf" is not supported by EPUB format},
      fn -> generate_docs(doc_config(assets: "test/tmp/epub_assets")) end
    )
  after
    File.rm_rf!("test/tmp/epub_assets")
  end

  test "генерирует файл EPUB в каталоге по умолчанию" do
    generate_docs(doc_config())
    assert File.regular?("#{output_dir()}/#{doc_config()[:project]}.epub")
  end

  test "генерирует файл EPUB в указанном выходном каталоге" do
    config = doc_config(output: "#{output_dir()}/another_dir", main: "RandomError")
    generate_docs(config)

    assert File.regular?("#{output_dir()}/another_dir/#{doc_config()[:project]}.epub")
  end

  test "генерирует файл EPUB со стандартизированной структурой" do
    generate_docs_and_unzip(doc_config())

    root_dir = "#{output_dir()}"
    meta_dir = "#{root_dir}/META-INF"
    oebps_dir = "#{root_dir}/ОБПС"
    dist_dir = "#{oebps_dir}/расстояние"

    assert File.regular?("#{root_dir}/mimetype")
    assert File.regular?("#{meta_dir}/container.xml")
    assert File.regular?("#{meta_dir}/com.apple.ibooks.display-options.xml")
    assert File.regular?("#{oebps_dir}/content.opf")
    assert File.regular?("#{oebps_dir}/nav.xhtml")
    assert File.regular?("#{oebps_dir}/title.xhtml")
    assert File.regular?("#{oebps_dir}/readme.xhtml")
    assert File.regular?("#{oebps_dir}/CompiledWithDocs.xhtml")
    assert File.regular?("#{oebps_dir}/CompiledWithDocs.Nested.xhtml")
    assert "#{dist_dir}/epub*.css" |> Path.wildcard() |> List.first() |> File.regular?()
    assert "#{dist_dir}/epub*.js" |> Path.wildcard() |> List.first() |> File.regular?()
  end

  test "генерирует все файлы листинга" do
    generate_docs_and_unzip(doc_config())
    content = File.read!("#{output_dir()}/OEBPS/content.opf")

    assert content =~ ~r{.*"CompiledWithDocs\".*}ms
    утверждать содержимое =~ ~r{.*"CompiledWithDocs.Nested\".*}мс
    утверждать содержимое =~ ~r{.*"UndefParent\.Nested\".*}мс
    утверждать содержимое =~ ~r{.*"CustomBehaviourOne\".*}мс
    утверждать содержимое =~ ~r{.*"CustomBehaviourTwo\".*}мс
    опровергнуть содержимое =~ ~r{UndefParent\.Undocumented}ms
    утверждать содержимое =~ ~r{.*"RandomError\".*}мс
    утверждать содержимое =~ ~r{.*"CustomProtocol\".*}мс
    утверждать содержимое =~ ~r{.*"Mix\.Tasks\.TaskWithDocs\".*}мс
  конец

  тест "generates the readme file" делать
    конфигурация = doc_config(основная: "README")
    генерировать_docs_and_unzip (конфигурация)

    содержимое = File.read!("#{output_dir()}/OEBPS/readme.xhtml")
    assert content =~ ~r{<title>README [^<]*</title>}
    assert content =~ ~r{<a href="RandomError.xhtml"><code(\sclass="inline")?>RandomError</code>}

    assert content =~
             ~r{<a href="CustomBehaviourImpl.xhtml#hello/1"><code(\sclass="inline")?>CustomBehaviourImpl.hello/1</code>}

    assert content =~
             ~r{<a href="TypesAndSpecs.Sub.xhtml"><code(\sclass="inline")?>TypesAndSpecs.Sub</code></a>}

    content = File.read!("#{output_dir()}/OEBPS/nav.xhtml")
    assert content =~ ~r{<li><a href="readme.xhtml">README</a></li>}
  end

  test "использует samp в качестве тега выделения для уценки" do
    generate_docs_and_unzip(doc_config())

    assert File.read!("#{output_dir()}/OEBPS/CompiledWithDocs.xhtml") =~
             "<samp class=\"nc\">CompiledWithDocs<\/samp>"
  end

  describe "before_closing__*_tags" do
    # Есть три возможности для `before_closing__*_tags`:
    # - требуется только пользователю
    # - требуется только обработчику уценки
    # - требуется как обработчику уценки, так и пользователю
    # Мы проверим три возможности независимо

    @example_basenames [
      # «структурные» страницы
      "nav.xhtml",
      "title.xhtml",
      "readme.xhtml",
      # "страницы модуля"
      "CompiledWithDocs.xhtml",
      "CompiledWithDocs.Nested.xhtml"
    ]

    # 1. требуется пользователю
    test "необходимые пользователю находятся в нужном месте" do
      generate_docs_and_unzip(
        doc_config(
          before_closing_head_tag: &before_closing_head_tag/1,
          before_closing_body_tag: &before_closing_body_tag/1
        )
      )

      oebps_dir = "#{output_dir()}/ОБПС"

      for basename <- @example_basenames do
        content = File.read!(Path.join(oebps_dir, basename))
        assert content =~ ~r[#{@before_closing_head_tag_content_epub}\s*</head>]
        assert content =~ ~r[#{@before_closing_body_tag_content_epub}\s*</body>]

        assert not (content =~ ~r[#{DummyProcessor.before_closing_head_tag(:epub)}\s*</head>])
        assert not (content =~ ~r[#{DummyProcessor.before_closing_body_tag(:epub)}\s*</body>])
      end
    end

    # 2. Требуется обработчиком уценки
    test "требуемые обработчиком уценки, находятся в нужном месте" do
      generate_docs_and_unzip(doc_config(markdown_processor: DummyProcessor))
      oebps_dir = "#{output_dir()}/ОБПС"

      for basename <- @example_basenames do
        content = File.read!(Path.join(oebps_dir, basename))
        assert content =~ ~r[#{DummyProcessor.before_closing_head_tag(:epub)}\s*</head>]
        assert content =~ ~r[#{DummyProcessor.before_closing_body_tag(:epub)}\s*</body>]
        assert not (content =~ ~r[#{@before_closing_head_tag_content_epub}\s*</head>])
        assert not (content =~ ~r[#{@before_closing_body_tag_content_epub}\s*</body>])
      end
    end

    # 3. Требуется как пользователю, так и процессору уценки.
    test "required by (1) the user and (2) the markdown processor are in the right place" do
      generate_docs_and_unzip(
        doc_config(
          before_closing_head_tag: &before_closing_head_tag/1,
          before_closing_body_tag: &before_closing_body_tag/1,
          markdown_processor: DummyProcessor
        )
      )

      oebps_dir = "#{output_dir()}/ОБПС"

      for basename <- @example_basenames do
        content = File.read!(Path.join(oebps_dir, basename))

        assert content =~
                 ~r[#{DummyProcessor.before_closing_head_tag(:epub)}\s*#{
                   @before_closing_head_tag_content_epub
                 }\s*</head>]

        assert content =~
                 ~r[#{DummyProcessor.before_closing_body_tag(:epub)}\s*#{
                   @before_closing_body_tag_content_epub
                 }\s*</body>]
      end
    end
  end

  describe "assets" do
    # При необходимости есть 3 возможности:
    # - требуется только пользователю
    # - требуется только обработчику уценки
    # - требуется как обработчику уценки, так и пользователю
    # Мы проверим три возможности независимо

    # 1. Требуется только пользователю
    test "требуемые пользователем, оказываются в нужном месте" do
      File.mkdir_p!("test/tmp/epub_assets/hello")
      File.touch!("test/tmp/epub_assets/hello/world.png")

      generate_docs_and_unzip(
        doc_config(
          assets: "test/tmp/epub_assets",
          logo: "test/fixtures/elixir.png",
          cover: "test/fixtures/elixir.png"
        )
      )

      assert File.regular?("#{output_dir()}/OEBPS/assets/hello/world.png")
      assert File.regular?("#{output_dir()}/OEBPS/assets/logo.png")
      assert File.regular?("#{output_dir()}/OEBPS/assets/cover.png")
    after
      File.rm_rf!("test/tmp/epub_assets")
    end

    # 2. Требуется обработчиком уценки
    test "требуемые обработчиком уценки, оказываются в нужном месте" do
      generate_docs_and_unzip(doc_config(markdown_processor: DummyProcessor))
      # Проверьте активы, добавленные обработчиком уценки.
      for [{filename, content}] <- DummyProcessor.assets(:html) do
        # Имя файла совпадает
        assert File.regular?("#{output_dir()}/#{filename}")
        # Содержимое совпадает
        assert File.read!("#{output_dir()}/#{filename}") == content
      end
    after
      File.rm_rf!("test/tmp/epub_assets")
    end

    # 3. Требуется пользователю и обработчику уценки.
    test "required by the user and markdown processor end up in the right place" do
      File.mkdir_p!("test/tmp/epub_assets/hello")
      File.touch!("test/tmp/epub_assets/hello/world.png")

      generate_docs_and_unzip(
        doc_config(
          markdown_processor: DummyProcessor,
          assets: "test/tmp/epub_assets",
          logo: "test/fixtures/elixir.png",
          cover: "test/fixtures/elixir.png"
        )
      )

      assert File.regular?("#{output_dir()}/OEBPS/assets/hello/world.png")
      assert File.regular?("#{output_dir()}/OEBPS/assets/logo.png")
      assert File.regular?("#{output_dir()}/OEBPS/assets/cover.png")
      # Проверьте активы, добавленные обработчиком уценки.
      for [{filename, content}] <- DummyProcessor.assets(:html) do
        # Имя файла совпадает
        assert File.regular?("#{output_dir()}/#{filename}")
        # Содержимое совпадает
        assert File.read!("#{output_dir()}/#{filename}") == content
      end
    after
      File.rm_rf!("test/tmp/epub_assets")
    end
  end
end
