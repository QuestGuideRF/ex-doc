defmodule ExDoc.RetrieverTest do
  use ExUnit.Case, async: true

  alias ExDoc.Retriever

  defp docs_from_files(names, config \\ []) do
    files = Enum.map(names, fn n -> "test/tmp/Elixir.#{n}.beam" end)

    default = %ExDoc.Config{
      source_url_pattern: "http://example.com/%{path}#L%{line}",
      source_root: File.cwd!()
    }

    Retriever.docs_from_files(files, struct(default, config))
  end

  describe "docs_from_dir" do
    test "соответствует файлам с префиксом фильтра" do
      config = %ExDoc.Config{filter_prefix: "CompiledWithDocs", source_root: File.cwd!()}
      from_dir_nodes = Retriever.docs_from_dir("test/tmp/beam", config)

      file_nodes =
        ["Elixir.CompiledWithDocs.beam", "Elixir.CompiledWithDocs.Nested.beam"]
        |> Enum.map(&Path.join("test/tmp/beam", &1))
        |> Retriever.docs_from_files(config)

      assert from_dir_nodes == file_nodes
    end
  end

  describe "modules" do
    test "возвращает узлы модуля" do
      [module_node] = docs_from_files(["CompiledWithDocs"])
      assert module_node.id == "CompiledWithDocs"
      assert module_node.title == "CompiledWithDocs"
      assert module_node.module == CompiledWithDocs
      refute module_node.group
      refute module_node.nested_context
      refute module_node.nested_title
      assert module_node.source_url == "http://example.com/test/fixtures/compiled_with_docs.ex#L1"

      assert module_node.doc == """
             модульдок

             ## Пример ☃ Юникод > экранирование
                 CompiledWithDocs.example

             ### Пример заголовка H3

             пример
             """
    end

    test "возвращает группу модулей" do
      [module_node] =
        docs_from_files(["CompiledWithDocs"], groups_for_modules: [Group: [CompiledWithDocs]])

      assert module_node.group == :Group

      [module_node] =
        docs_from_files(["CompiledWithDocs"], groups_for_modules: [Group: ["CompiledWithDocs"]])

      assert module_node.group == :Group

      [module_node] =
        docs_from_files(["CompiledWithDocs"], groups_for_modules: [Group: ~r/^CompiledWith.?/])

      assert module_node.group == :Group
    end

    test "возвращает информацию о вложении" do
      prefix = "Common.Nesting.Prefix"

      module_nodes =
        docs_from_files([prefix <> ".Foo", prefix <> ".Bar"], nest_modules_by_prefix: [prefix])

      assert length(module_nodes) > 0

      for module_node <- module_nodes do
        assert module_node.nested_context == prefix
        assert module_node.nested_title in ~w(Foo Bar)
      end

      name = "Common.Nesting.Prefix.Foo"
      [module_node] = docs_from_files([name], nest_modules_by_prefix: [name])

      refute module_node.nested_context
      refute module_node.nested_title
    end

    test "возвращает функциональные узлы для каждого модуля" do
      [module_node] =
        docs_from_files(["CompiledWithDocs"],
          groups_for_functions: [
            Example: &(&1[:purpose] == :example),
            Legacy: &is_binary(&1[:deprecated])
          ]
        )

      [struct, example, example_1, example_with_h3, example_without_docs, flatten, is_zero] =
        module_node.docs

      assert struct.id == "__struct__/0"
      assert struct.doc == "Некоторая структура"
      assert struct.type == :function
      assert struct.defaults == []
      assert struct.signature == "%CompiledWithDocs{}"
      assert struct.group == "Functions"

      assert example.id == "example/2"
      assert example.doc == "Некоторые примеры"
      assert example.type == :function
      assert example.defaults == ["example/1"]
      assert example.signature == "пример(foo, bar \\\\ Баз)"
      assert example.deprecated == "Вместо этого используйте что-нибудь другое"
      assert example.group == "Example"

      assert example_1.id == "example_1/0"
      assert example_1.type == :macro
      assert example_1.defaults == []
      assert example_1.annotations == ["macro", "с версии 1.3.0"]

      assert example_with_h3.id == "example_with_h3/0"
      assert example_with_h3.group == "Example"

      assert example_without_docs.id == "example_without_docs/0"
      assert example_without_docs.doc == nil
      assert example_without_docs.defaults == []
      assert example_without_docs.group == "Legacy"

      assert example_without_docs.source_url ==
               "http://example.com/test/fixtures/compiled_with_docs.ex\#L38"

      assert flatten.id == "flatten/1"
      assert flatten.type == :function

      if Version.match?(System.version(), ">= 1.8.0") do
        assert flatten.doc == "См. `List.flatten/1`."
      end

      assert is_zero.id == "is_zero/1"
      assert is_zero.doc == "Простой охранник"
      assert is_zero.type == :macro
      assert is_zero.defaults == []
    end

    test "возвращает спецификации для каждой закрытой функции" do
      [module_node] = docs_from_files(["TypesAndSpecs"])
      [add, _, _] = module_node.docs

      assert add.id == "add/2"
      assert add.doc == nil
      assert add.type == :function
      assert Macro.to_string(add.specs) == "[add(integer(), opaque()) :: целое()]"
    end

    test "возвращает спецификации для неприватных макросов" do
      [module_node] = docs_from_files(["TypesAndSpecs"])
      [_, _, macro] = module_node.docs

      assert macro.id == "macro_spec/1"
      assert macro.doc == nil
      assert macro.type == :macro
      assert Macro.to_string(macro.specs) == "[macro_spec(any()) :: {:ok, any()}]"
    end

    test "возвращает информацию о спецификации для каждого типа закрытого модуля" do
      [module_node] = docs_from_files(["TypesAndSpecs"])
      [opaque, public, ref] = module_node.typespecs

      assert opaque.name == :opaque
      assert opaque.arity == 0
      assert opaque.id == "opaque/0"
      assert opaque.type == :opaque
      assert opaque.signature == "непрозрачный()"
      assert Macro.to_string(opaque.spec) == "непрозрачный()"

      assert public.name == :public
      assert public.arity == 1
      assert public.id == "public/1"
      assert public.type == :type
      assert public.doc == "Публичный тип"
      assert public.signature == "public(t)"

      assert Macro.to_string(public.spec) ==
               "public(t) :: {t, String.t(), TypesAndSpecs.Sub.t(), opaque(), :ok | :error}"

      assert ref.name == :ref
      assert ref.arity == 0
      assert ref.id == "ref/0"
      assert ref.type == :type
      assert ref.signature == "ссылка()"
      assert Macro.to_string(ref.spec) == "ref() :: {:binary.part(), public(any())}"
    end

    test "возвращает источник, когда source_root установлен в ноль" do
      files = Enum.map(["CompiledWithDocs"], fn n -> "test/tmp/Elixir.#{n}.beam" end)
      config = %ExDoc.Config{source_url_pattern: "%{path}:%{line}", source_root: nil}
      [module_node] = Retriever.docs_from_files(files, config)
      assert String.ends_with?(module_node.source_url, "/test/fixtures/compiled_with_docs.ex:1")
    end

    test "возвраты для модулей без документации" do
      [module_node] = docs_from_files(["CompiledWithoutDocs"])
      assert module_node.doc == nil
      assert module_node.docs == []
    end

    test "возвращает обратные вызовы без включенной документации" do
      [module_node] = docs_from_files(["CallbacksNoDocs"])
      [connect, id] = module_node.docs

      assert connect.id == "connect/2"
      assert connect.annotations == []

      assert id.id == "id/1"
      assert id.deprecated == "Использовать другой идентификатор"
      assert id.annotations == ["optional", "с версии 1.3.0"]
    end

    test "сбой, когда модуль недоступен" do
      assert_raise ExDoc.Retriever.Error, "модуль NotAvailable не определен/не доступен", fn ->
        docs_from_files(["NotAvailable"])
      end
    end
  end

  describe "exceptions" do
    test "правильно помечены" do
      [module_node] = docs_from_files(["RandomError"])
      assert module_node.type == :exception
    end
  end

  describe "tasks" do
    test "правильно помечены" do
      [module_node] = docs_from_files(["Mix.Tasks.TaskWithDocs"])
      assert module_node.type == :task
      assert module_node.id == "Mix.Tasks.TaskWithDocs"
      assert module_node.title == "смешать задачу_с_документами"
    end
  end

  ## ПОВЕДЕНИЕ

  describe "behaviours" do
    test "возвращает обратные вызовы (за исключением внутренних функций)" do
      [module_node] = docs_from_files(["CustomBehaviourOne"])
      functions = Enum.map(module_node.docs, fn doc -> doc.id end)
      assert functions == ["greet/1", "hello/1"]
      [greet, hello] = module_node.docs
      assert hello.type == :callback
      assert hello.signature == "привет(%UРИ{})"
      assert greet.type == :callback
      assert greet.signature == "приветствие(arg1)"
    end

    test "возвращает обратные вызовы макросов" do
      [module_node] = docs_from_files(["CustomBehaviourTwo"])
      functions = Enum.map(module_node.docs, fn doc -> doc.id end)
      assert functions == ["bye/1"]
      assert hd(module_node.docs).type == :macrocallback
      assert hd(module_node.docs).signature == "пока (целое число)"
    end

    test "недокументированные реализации обратного вызова получают документацию по умолчанию" do
      [module_node] =
        ["CustomBehaviourOne", "CustomBehaviourTwo", "CustomBehaviourImpl"]
        |> docs_from_files()
        |> Enum.filter(&match?(%ExDoc.ModuleNode{id: "CustomBehaviourImpl"}, &1))

      docs = module_node.docs
      assert Enum.map(docs, & &1.id) == ["bye/1", "greet/1", "hello/1"]

      assert Enum.at(docs, 0).doc ==
               "Документ для этого, чтобы он не использовал «Реализацию обратного вызова для»"

      assert Enum.at(docs, 1).doc == "Реализация обратного вызова для `c:CustomBehaviourOne.greet/1`."

      assert Enum.at(docs, 2).doc ==
               "Это пример обратного вызова.\n\n\n" <>
                 "Реализация обратного вызова для `c:CustomBehaviourOne.hello/1`."
    end
  end

  ## ПРОТОКОЛОВ

  describe "protocols" do
    test "правильно помечены" do
      [module_node] = docs_from_files(["CustomProtocol"])
      assert module_node.type == :protocol
    end

    test "игнорирует внутренние функции" do
      [module_node] = docs_from_files(["CustomProtocol"])
      functions = Enum.map(module_node.docs, fn doc -> doc.id end)
      assert functions == ["plus_one/1", "plus_two/1"]
    end
  end

  describe "implementations" do
    test "пропускаются" do
      assert [] = docs_from_files(["CustomProtocol.Number"])
    end
  end
end
