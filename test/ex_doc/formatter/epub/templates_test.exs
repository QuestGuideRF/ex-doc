defmodule ExDoc.Formatter.EPUB.TemplatesTest do
  use ExUnit.Case, async: true

  alias ExDoc.Formatter.HTML
  alias ExDoc.Formatter.EPUB.Templates

  defp source_url do
    "https://github.com/elixir-lang/elixir"
  end

  defp homepage_url do
    "http://elixir-lang.org"
  end

  defp doc_config(config \\ []) do
    default = %ExDoc.Config{
      project: "Elixir",
      version: "1.0.1",
      source_root: File.cwd!(),
      source_url_pattern: "#{source_url()}/blob/master/%{path}#L%{line}",
      homepage_url: homepage_url(),
      source_url: source_url(),
      output: "test/tmp/epub_templates"
    }

    struct(default, config)
  end

  defp get_module_page(names, config \\ []) do
    config = doc_config(config)
    mods = ExDoc.Retriever.docs_from_modules(names, config)
    {[mod | _], _} = HTML.autolink_and_render(mods, ".xhtml", config, highlight_tag: "samp")
    Templates.module_page(config, mod)
  end

  setup_all do
    File.mkdir_p!("test/tmp/epub_templates/OEBPS")
    File.cp_r!("formatters/epub", "test/tmp/epub_templates/OEBPS")
    :ok
  end

  describe "module_page" do
    test "генерирует только имя модуля, когда больше нет информации" do
      module_node = %ExDoc.ModuleNode{
        module: XPTOModule,
        doc: nil,
        id: "XPTOModule",
        title: "XPTOModule"
      }

      content = Templates.module_page(doc_config(), module_node)

      assert content =~ ~r{<title>XPTOModule [^<]*</title>}
      assert content =~ ~r{<h1 id="content">\s*XPTOModule\s*}
    end

    test "выводит функции и строки документации" do
      content = get_module_page([CompiledWithDocs])

      assert content =~ ~r{<title>CompiledWithDocs [^<]*</title>}
      assert content =~ ~r{<h1 id="content">\s*CompiledWithDocs\s*}

      assert content =~
               ~r{moduledoc.*Example.*<samp class="nc">CompiledWithDocs</samp><samp class="o">\.</samp><samp class="n">example</samp>.*}ms

      assert content =~ ~r{example/2.*Some example}ms
      assert content =~ ~r{example_without_docs/0.*<section class="docstring">.*</section>}ms
      assert content =~ ~r{example_1/0.*<span class="note">\(macro\)</span>}ms

      assert content =~ ~s{<section class="detail" id="example_1/0">}
      assert content =~ ~s{example(foo, bar \\\\ Baz)}
    end

    test "функциональные группы выходов" do
      content =
        get_module_page([CompiledWithDocs],
          groups_for_functions: [
            "Примеры функций": &(&1[:purpose] == :example),
            Legacy: &is_binary(&1[:deprecated])
          ]
        )

      assert content =~ ~r{id="example-functions".*href="#пример-функции".*Example functions}ms
      assert content =~ ~r{id="legacy".*href="#наследие".*Legacy}ms
      assert content =~ ~r{id="example-functions".*id="example/2"}ms
      refute content =~ ~r{id="legacy".*id="example/2"}ms
      refute content =~ ~r{id="functions".*id="example/2"}ms
      assert content =~ ~r{id="functions".*id="example_1/0"}ms
    end

    test "выводит сводные данные" do
      content = get_module_page([CompiledWithDocs])
      assert content =~ ~r{<div class="summary-signature">\s*<a href="#example_1/0">}
    end

    test "содержит ссылки на разделы сводки, если они существуют" do
      content = get_module_page([CompiledWithDocs, CompiledWithDocs.Nested])
      refute content =~ ~r{types_details}
    end

    ## ПОВЕДЕНИЕ

    test "выводит поведение и обратные вызовы" do
      content = get_module_page([CustomBehaviourOne])

      assert content =~
               ~r{<h1 id="content">\s*CustomBehaviourOne\s*<small>behaviour</small>\s*</h1>}m

      assert content =~ ~r{Callbacks}
      assert content =~ ~r{<section class="detail" id="c:hello/1">}

      content = get_module_page([CustomBehaviourTwo])

      assert content =~
               ~r{<h1 id="content">\s*CustomBehaviourTwo\s*<small>behaviour</small>\s*</h1>}m

      assert content =~ ~r{Callbacks}
      assert content =~ ~r{<section class="detail" id="c:bye/1">}
    end

    ## ПРОТОКОЛОВ

    test "выводит тип протокола" do
      content = get_module_page([CustomProtocol])
      assert content =~ ~r{<h1 id="content">\s*CustomProtocol\s*<small>protocol</small>\s*}m
    end

    ## ЗАДАЧИ

    test "выводит тип задачи" do
      content = get_module_page([Mix.Tasks.TaskWithDocs])
      assert content =~ ~r{<h1 id="content">\s*mix task_with_docs\s*}m
    end
  end
end
