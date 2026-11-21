defmodule ExDoc.Formatter.HTML.AutolinkTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias ExDoc.Formatter.HTML.Autolink

  @elixir_docs "https://hexdocs.pm/"
  @erlang_docs "http://www.erlang.org/doc/man/"

  describe "local" do
    test "автоссылки веселья/арности в документах" do
      assert project_doc("`пример/2`", %{locals: ["example/2"]}) == "[`пример/2`](#пример/2)"

      assert project_doc("`пример/1,2`", %{locals: ["example/1", "example/2"]}) ==
               "[`пример/1,2`](#пример/1)"

      assert project_doc("`__ENV__/0`", %{locals: ["__ENV__/0"]}) == "[`__ENV__/0`](#__ENV__/0)"

      assert project_doc("`пример/2`, затем `пример/2`", %{locals: ["example/2"]}) ==
               "[`example/2`](#example/2), затем [`example/2`](#example/2)"

      assert project_doc("`пробелы/0`", %{locals: ["spaces/0"]}) == "[`пробелы/0`](#пробелы/0)"

      assert project_doc("`пример/1` и `пример/2`", %{locals: ["example/1", "example/2"]}) ==
               "[`example/1`](#example/1) и [`example/2`](#example/2)"

      assert project_doc(
               "`смешное_имя\?/1` и `смешное_имя!/2`",
               %{locals: ["смешное_имя\?/1", "смешное_имя!/2"]}
             ) == "[`funny_name\?/1`](#funny_name\?/1) и [`funny_name!/2`](#funny_name!/2)"

      assert project_doc("`//2`", %{locals: ["//2"]}) == "[`//2`](#//2)"
    end

    test "автоссылки на локальные обратные вызовы" do
      # `split_function` также должна возвращать локально определенные обратные вызовы.
      # format should be: "c:<fun>/<arity>"
      assert project_doc("`с: веселье/2`", %{locals: ["c:fun/2"]}) == "[`fun/2`](#c:fun/2)"

      assert project_doc("`c:fun/1,2`", %{locals: ["c:fun/1", "c:fun/2"]}) ==
               "[`fun/1,2`](#c:fun/1)"
    end

    test "автоссылки на локальные типы" do
      assert project_doc("`t:my_type/0`", %{locals: ["t:my_type/0"]}) ==
               "[`my_type/0`](#t:my_type/0)"

      assert project_doc("`t:my_type/1`", %{locals: ["t:my_type/1"]}) ==
               "[`my_type/1`](#t:my_type/1)"

      assert project_doc("`t:my_type/1,2`", %{locals: ["t:my_type/1", "t:my_type/2"]}) ==
               "[`my_type/1,2`](#t:my_type/1)"

      # ссылки на типы без арности не работают
      assert project_doc("`t:my_type`", %{locals: ["t:my_type/0"]}) == "`t:my_type`"
    end

    test "автоссылки на базовые и встроенные типы" do
      assert project_doc("`т:атом/0`", %{}) ==
               "[`atom/0`](#{@elixir_docs}elixir/typespecs.html#basic-types)"

      assert project_doc("`т:терм/0`", %{}) ==
               "[`term/0`](#{@elixir_docs}elixir/typespecs.html#built-in-types)"
    end

    test "не автоматически связывает неопределенные функции" do
      assert project_doc("`пример/1`", %{locals: ["example/2"]}) == "`пример/1`"
      assert project_doc("`пример/1,2`", %{locals: ["example/1"]}) == "`пример/1,2`"

      assert project_doc("`пример/1,2,3`", %{locals: ["example/1", "example/2"]}) ==
               "`пример/1,2,3`"

      assert project_doc("`пример/1`", %{}) == "`пример/1`"
    end

    test "не автоматически связывает предварительно связанные функции" do
      assert project_doc("[`пример/1`]()", %{locals: ["example/1"]}) == "[`пример/1`]()"
      assert project_doc("[пример/1]()", %{locals: ["example/1"]}) == "[пример/1]()"
    end

    test "не выполняет автоматическую ссылку на функции с несколькими арностями в неправильном порядке" do
      assert project_doc("`пример/2,1`", %{locals: ["example/1", "example/2"]}) ==
               "`пример/2,1`"
    end

    test "специальные формы автоссылок" do
      assert project_doc("`{}/1`", %{locals: ["{}/1"]}) == "[`{}/1`](#%7B%7D/1)"
      assert project_doc("`<<>>/1`", %{locals: ["<<>>/1"]}) == "[`<<>>/1`](#%3C%3C%3E%3E/1)"

      assert project_doc("`<<>>/1`", %{}) ==
               "[`<<>>/1`](#{@elixir_docs}elixir/Kernel.SpecialForms.html#%3C%3C%3E%3E/1)"

      assert project_doc("`<<>>/1`", %{aliases: [Kernel]}) ==
               "[`<<>>/1`](Kernel.SpecialForms.html#%3C%3C%3E%3E/1)"
    end

    test "автоссылки Функции ядра" do
      assert project_doc("`абс/1`", %{locals: ["abs/1"]}) == "[`абс/1`](#абс/1)"

      assert project_doc("`абс/1`", %{}) == "[`abs/1`](#{@elixir_docs}elixir/Kernel.html#abs/1)"

      assert project_doc("`!/1`", %{locals: ["!/1"]}) == "[`!/1`](#!/1)"
      assert project_doc("`!/1`", %{}) == "[`!/1`](#{@elixir_docs}elixir/Kernel.html#!/1)"
      assert project_doc("`!/1`", %{aliases: [Kernel]}) == "[`!/1`](Kernel.html#!/1)"

      assert project_doc("`поднять/1,2`", %{aliases: [Kernel]}) ==
               "[`raise/1,2`](Kernel.html#raise/1)"
    end
  end

  describe "функции эликсира" do
    test "автоссылки Module.fun/arity в документах" do
      assert project_doc("`Mod.example/2`", %{docs_refs: ["Mod.example/2"]}) ==
               "[`Mod.example/2`](Mod.html#example/2)"

      assert project_doc("`Mod.example/1,2`", %{docs_refs: ["Mod.example/1", "Mod.example/2"]}) ==
               "[`Mod.example/1,2`](Mod.html#example/1)"

      assert project_doc("`Мод.__ENV__/2`", %{docs_refs: ["Mod.__ENV__/2"]}) ==
               "[`Mod.__ENV__/2`](Mod.html#__ENV__/2)"

      assert project_doc("`MyModule.example/2`", %{docs_refs: ["MyModule.example/2"]}) ==
               "[`MyModule.example/2`](MyModule.html#example/2)"

      assert project_doc(
               "`MyModule.Nested.example/2`",
               %{docs_refs: ["MyModule.Nested.example/2"]}
             ) == "[`MyModule.Nested.example/2`](MyModule.Nested.html#example/2)"

      assert project_doc("`Mod.example/2`, затем `Mod.example/2`", %{docs_refs: ["Mod.example/2"]}) ==
               "[`Mod.example/2`](Mod.html#example/2), затем [`Mod.example/2`](Mod.html#example/2)"

      assert project_doc("` MyModule.spaces/0 `", %{docs_refs: ["MyModule.spaces/0"]}) ==
               "[`MyModule.spaces/0`](MyModule.html#spaces/0)"

      assert project_doc(
               "`ModA.example/1` и `ModB.example/2`",
               %{docs_refs: ["ModA.example/1", "ModB.example/2"]}
             ) ==
               "[`ModA.example/1`](ModA.html#example/1) и [`ModB.example/2`](ModB.html#example/2)"

      assert project_doc(
               "`Mod.funny_name\?/1` и `Mod.funny_name!/2`",
               %{docs_refs: ["Мод.funny_name\?/1", "Мод.смешное_имя!/2"]}
             ) ==
               "[`Mod.funny_name\?/1`](Mod.html#funny_name\?/1) и [`Mod.funny_name!/2`](Mod.html#funny_name!/2)"
    end

    test "предупреждает, когда модуль существует, но функция не работает" do
      compiled = %{
        docs_refs: ["Mod.example/1"],
        modules_refs: ["Mod"],
        skip_undefined_reference_warnings_on: ["Bar", "deprecations"]
      }

      assert capture_io(:stderr, fn ->
               assert Autolink.project_doc("`Mod.example/2`", "Mod.foo/0", compiled) ==
                        "`Mod.example/2`"
             end) =~ ~r"ссылки Mod.example/2 .* \(анализ Mod.foo/0 docs\)"

      assert capture_io(:stderr, fn ->
               assert Autolink.project_doc("[название](`Mod.example/2`)", "Mod.foo/0", compiled) ==
                        "title"
             end) =~ ~r"ссылки Mod.example/2 .* \(анализ Mod.foo/0 docs\)"

      assert capture_io(:stderr, fn ->
               assert Autolink.project_doc("`Mod.example/2`", "extras", compiled) ==
                        "`Mod.example/2`"
             end) =~ ~r"ссылки Mod.example/2 .* \(синтаксический анализ дополнительных документов\)"

      assert capture_io(:stderr, fn ->
               assert Autolink.project_doc("[название](`пример/2`)", "Mod.foo/0", compiled) ==
                        "title"
             end) =~ ~r"ссылки example/2 .* \(анализ Mod.foo/0 docs\)"

      assert capture_io(:stderr, fn ->
               assert Autolink.project_doc("[название](`Mod.example/1,2`)", "Mod.foo/0", compiled) ==
                        "title"
             end) =~ ~r"ссылки Mod.example/1,2 .* \(анализ Mod.foo/0 документов\)"

      # пропустить предупреждение, когда страница модуля занесена в черный список
      overwritten = Map.put(compiled, :module_id, "Bar")
      assert assert project_doc("`Mod.example/2`", "Mod.bar/0", overwritten) == "`Mod.example/2`"

      # пропустить предупреждение, когда страница дополнений занесена в черный список
      assert assert project_doc("`Mod.example/2`", "deprecations", compiled) == "`Mod.example/2`"
    end

    test "функции автоссылки Module.fun/arity в эликсире" do
      assert project_doc("`String.upcase/1`", %{}) ==
               "[`String.upcase/1`](#{@elixir_docs}elixir/String.html#upcase/1)"

      assert project_doc("`Файл.cd!/1,2`", %{}) ==
               "[`File.cd!/1,2`](#{@elixir_docs}elixir/File.html#cd!/1)"

      assert project_doc("`Mix.env/0`", %{}) ==
               "[`Mix.env/0`](#{@elixir_docs}mix/Mix.html#env/0)"
    end

    test "автоссылки на самый длинный каталог libdir" do
      lib_dir = :code.where_is_file('Elixir.CompiledWithDocs.beam')

      lib_dirs = [
        {Path.dirname(Path.dirname(lib_dir)), "http://short/"},
        {Path.dirname(lib_dir), "http://long/"}
      ]

      assert project_doc("`CompiledWithDocs.example/2`", %{
               docs_refs: [],
               extension: ".html",
               lib_dirs: lib_dirs
             }) == "[`CompiledWithDocs.example/2`](http://long/CompiledWithDocs.html#example/2)"
    end

    test "специальные формы автоссылок" do
      assert project_doc("`Мод.++/2`", %{docs_refs: ["Мод.++/2"]}) ==
               "[`Mod.++/2`](Mod.html#++/2)"

      assert project_doc("`Мод.!/1`", %{docs_refs: ["Мод.!/1"]}) == "[`Mod.!/1`](Mod.html#!/1)"

      assert project_doc("`Мод.../2`", %{docs_refs: ["Mod.../2"]}) ==
               "[`Mod.../2`](Mod.html#../2)"

      assert project_doc("`Мод.--/2`", %{docs_refs: ["Mod.--/2"]}) ==
               "[`Mod.--/2`](Mod.html#--/2)"

      assert project_doc("`Мод.%/2`", %{docs_refs: ["Мод.%/2"]}) == "[`Mod.%/2`](Mod.html#%25/2)"

      assert project_doc("`Мод.<<>>/1`", %{docs_refs: ["Мод.<<>>/1"]}) ==
               "[`Mod.<<>>/1`](Mod.html#%3C%3C%3E%3E/1)"
    end

    test "обратные вызовы автоссылок" do
      assert project_doc("`c:Mod.++/2`", %{docs_refs: ["с: Мод.++/2"]}) ==
               "[`Mod.++/2`](Mod.html#c:++/2)"

      assert project_doc(
               "`c:Mod.++/1,2`",
               %{docs_refs: ["с: Мод.++/1", "с: Мод.++/2"]}
             ) == "[`Mod.++/1,2`](Mod.html#c:++/1)"
    end

    test "типы автоссылок" do
      # используйте тот же подход для elixir_functions, что и для локальных переменных
      assert project_doc(
               "`t:MyModule.my_type/0`",
               %{docs_refs: ["t:MyModule.my_type/0"]}
             ) == "[`MyModule.my_type/0`](MyModule.html#t:my_type/0)"

      assert project_doc(
               "`t:MyModule.my_type/0,1`",
               %{docs_refs: ["t:MyModule.my_type/0", "t:MyModule.my_type/1"]}
             ) == "[`MyModule.my_type/0,1`](MyModule.html#t:my_type/0)"

      assert project_doc(
               "`t:MyModule.my_type`",
               %{docs_refs: ["t:MyModule.my_type/0"]}
             ) == "`t:MyModule.my_type`"
    end

    test "не выполняет автолинковку неопределенных мод.функций" do
      assert project_doc("`Mod.example/1`", %{docs_refs: ["Mod.example/2"]}) == "`Mod.example/1`"
      assert project_doc("`Mod.example/1`", %{}) == "`Mod.example/1`"
    end

    test "не выполняет автоматическую привязку предварительно связанных функций Mod.functions" do
      assert project_doc("[`Mod.example/1`]()", %{docs_refs: ["Mod.example/1"]}) ==
               "[`Mod.example/1`]()"

      assert project_doc("[Mod.example/1`]()", %{docs_refs: ["Mod.example/1"]}) ==
               "[Mod.example/1`]()"

      assert project_doc("[`Mod.example/1`](foo)", %{docs_refs: ["Mod.example/1"]}) ==
               "[`Mod.example/1`](foo)"

      assert project_doc("[Mod.example/1`](foo)", %{docs_refs: ["Mod.example/1"]}) ==
               "[Mod.example/1`](foo)"
    end

    test "поддерживает обычные ссылки" do
      assert project_doc("`Mod.example/1`", %{docs_refs: ["Mod.example/1"]}) ==
               "[`Mod.example/1`](Mod.html#example/1)"

      assert project_doc("(`Mod.example/1`)", %{docs_refs: ["Mod.example/1"]}) ==
               "([`Mod.example/1`](Mod.html#example/1))"

      # Он игнорирует ссылки, которым предшествует "]("
      assert project_doc("](`Mod.example/1`)", %{docs_refs: ["Mod.example/1"]}) ==
               "](`Mod.example/1`)"
    end

    test "поддерживает пользовательские ссылки" do
      assert project_doc("[`пример`](`Mod.example/1`)", %{docs_refs: ["Mod.example/1"]}) ==
               "[`пример`](Mod.html#example/1)"

      assert project_doc("[пример](`Mod.example/1`)", %{docs_refs: ["Mod.example/1"]}) ==
               "[пример](Mod.html#example/1)"

      assert project_doc("[Mod.example/1`](`Mod.example/1`)", %{docs_refs: ["Mod.example/1"]}) ==
               "[Mod.example/1`](Mod.html#example/1)"

      assert project_doc("[`callback(a)`](`c:Foo.foo/1`)", %{docs_refs: ["c:Foo.foo/1"]}) ==
               "[`callback(a)`](Foo.html#c:foo/1)"

      assert project_doc("[upcase](`String.upcase/1`)", %{docs_refs: []}) ==
               "[upcase`](#{@elixir_docs}elixir/String.html#upcase/1)"

      assert project_doc("[`f`](`Foo.foo/1`), [`f`](`Foo.foo/1`)", %{docs_refs: ["Foo.foo/1"]}) ==
               "[`f`](Foo.html#foo/1), [`f`](Foo.html#foo/1)"

      assert project_doc("[`foo`](`Foo.//2`)", %{docs_refs: ["Foo.//2"]}) ==
               "[`foo`](Foo.html#//2)"

      assert project_doc("[`for`](`Kernel.SpecialForms.for/1`)", %{docs_refs: []}) ==
               "[`for`](#{@elixir_docs}elixir/Kernel.SpecialForms.html#for/1)"

      assert project_doc("[`за`](`за/1`)", %{docs_refs: []}) ==
               "[`for`](#{@elixir_docs}elixir/Kernel.SpecialForms.html#for/1)"

      assert project_doc("[`is_boolean`](`Kernel.is_boolean/1`)", %{docs_refs: []}) ==
               "[`is_boolean`](#{@elixir_docs}elixir/Kernel.html#is_boolean/1)"

      assert project_doc("[`is_boolean`](`is_boolean/1`)", %{docs_refs: []}) ==
               "[`is_boolean`](#{@elixir_docs}elixir/Kernel.html#is_boolean/1)"

      assert project_doc("[term()](`t:term/0`)", %{docs_refs: []}) ==
               "[term()](#{@elixir_docs}elixir/typespecs.html#built-in-types)"

      assert project_doc("[термин\(\)](`t:term/0`)", %{docs_refs: []}) ==
               "[term\(\)](#{@elixir_docs}elixir/typespecs.html#built-in-types)"

      assert project_doc("[`term()`](`t:term/0`)", %{docs_refs: []}) ==
               "[`term()`](#{@elixir_docs}elixir/typespecs.html#built-in-types)"

      assert project_doc("[`term()`](`t:term/0`)", %{docs_refs: []}) ==
               "[`term()`](#{@elixir_docs}elixir/typespecs.html#built-in-types)"

      assert project_doc("[версия](`t:Version.version/0`)", %{docs_refs: ["t:Version.version/0"]}) ==
               "[версия](Версия.html#t:версия/0)"
    end
  end

  describe "эликсирные модули" do
    test "модули автоссылки в документах" do
      assert project_doc("`МойМодуль`", %{docs_refs: ["MyModule"], module_id: "MyModule"}) ==
               "[`MyModule`](#content)"

      assert project_doc("`MyModule.Nested`", %{
               docs_refs: ["MyModule.Nested"],
               module_id: "MyModule.Nested"
             }) == "[`MyModule.Nested`](#content)"

      assert project_doc("`MyModule.Nested.Deep`", %{
               docs_refs: ["MyModule.Nested.Deep"],
               module_id: "MyModule.Nested.Deep"
             }) == "[`MyModule.Nested.Deep`](#content)"

      assert project_doc("```\nThis is a test.\n```\n\nSee `MyModule`.", %{
               docs_refs: ["MyModule"],
               module_id: "MyModule"
             }) == "```\nThis is a test.\n```\n\nSee [`MyModule`](#content)."
    end

    test "модули автоссылки в эликсире" do
      assert project_doc("`Строка`", %{docs_refs: ["MyModule"], module_id: "MyModule"}) ==
               "[`String`](#{@elixir_docs}elixir/String.html)"

      assert project_doc("`Микс`", %{docs_refs: ["MyModule"], module_id: "MyModule"}) ==
               "[`Mix`](#{@elixir_docs}mix/Mix.html)"
    end

    test "модули зависимостей автоссылки" do
      lib_dirs = [{Application.app_dir(:earmark), "#{@elixir_docs}целевая/"}]

      assert project_doc("`Цель`", %{
               docs_refs: ["MyModule"],
               module_id: "MyModule",
               extension: ".html",
               lib_dirs: lib_dirs
             }) == "[`Earmark`](#{@elixir_docs}earmark/Earmark.html)"
    end

    test "не автоматически связывает неопределенные модули" do
      assert project_doc("`МойМодуль`", %{docs_refs: []}) == "`МойМодуль`"
      assert project_doc("`МойМодуль`", %{docs_refs: ["DiffModule"]}) == "`МойМодуль`"

      assert project_doc("`MyModule.Nested`", %{docs_refs: ["MyModule.DiffNested"]}) ==
               "`MyModule.Nested`"
    end

    test "не выполняет автоматическое связывание предварительно связанных модулей" do
      assert project_doc("[`Мод`](other.html)", %{docs_refs: ["Mod"]}) == "[`Мод`](other.html)"

      assert project_doc("[`Мод`](other.html)", %{docs_refs: ["Mod"]}) ==
               "[`Мод`](other.html)"

      assert project_doc("[Mod.Nested`](other.html)", %{docs_refs: ["Mod.Nested"]}) ==
               "[Mod.Nested`](other.html)"

      assert project_doc("[в модуле «Ядро»](Kernel.html#guards)", %{
               docs_refs: ["Kernel"]
             }) == "[в модуле «Ядро»](Kernel.html#guards)"

      assert project_doc("[в модуле «Ядро»](Kernel.html#guards)", %{docs_refs: []}) ==
               "[в модуле «Ядро»](Kernel.html#guards)"
    end

    test "поддерживает пользовательские ссылки" do
      assert project_doc("[`пример`](`Пример`)", %{modules_refs: ["Example"]}) ==
               "[`пример`](Example.html)"

      assert project_doc("[модуль `example`](`Пример`)", %{modules_refs: ["Example"]}) ==
               "[модуль `example`](Example.html)"

      assert project_doc("[модуль `Пример`](`Пример`)", %{modules_refs: ["Example"]}) ==
               "[модуль `Example`](Example.html)"

      assert project_doc("[модуль `string`](`String`)", %{modules_refs: []}) ==
               "[модуль `string`](#{@elixir_docs}elixir/String.html)"

      assert project_doc("[модуль `String`](`String`)", %{modules_refs: []}) ==
               "[модуль `String`](#{@elixir_docs}elixir/String.html)"
    end
  end

  describe "Смешивайте задачи" do
    test "автоссылки на встроенные задачи" do
      assert project_doc("`смешать тест`", %{}) ==
               "[`mix test`](#{@elixir_docs}mix/Mix.Tasks.Test.html)"
    end

    test "автоматически связывает пользовательские задачи" do
      assert project_doc("`смешать foo.bar.baz`", %{modules_refs: ["Mix.Tasks.Foo.Bar.Baz"]}) ==
               "[`mix foo.bar.baz`](Mix.Tasks.Foo.Bar.Baz.html)"
    end

    test "задача автоссылки в том же модуле" do
      assert project_doc("`смешать фу`", %{
               modules_refs: ["Mix.Tasks.Foo"],
               module_id: "Mix.Tasks.Foo"
             }) == "[`mix foo`](#content)"
    end

    test "автоматически связывает задачи из зависимостей" do
      lib_dirs = [{Application.app_dir(:nimble_parsec), "#{@elixir_docs}nimble_parsec/"}]

      assert project_doc("`смешать nimble_parsec.compile`", %{lib_dirs: lib_dirs}) ==
               "[`mix nimble_parsec.compile`](#{@elixir_docs}nimble_parsec/Mix.Tasks.NimbleParsec.Compile.html)"
    end

    test "автоссылки шестнадцатеричных задач" do
      assert project_doc("`смешать hex.publish`", %{}) ==
               "[`mix hex.publish`](#{@elixir_docs}hex/Mix.Tasks.Hex.Publish.html)"
    end

    test "справка по задаче автоссылки" do
      assert project_doc("`смешать помощь компиляции.приложение`", %{}) ==
               "[`mix help compile.app`](#{@elixir_docs}mix/Mix.Tasks.Compile.App.html)"
    end

    test "не связывает задачу автоматически с аргументами" do
      assert project_doc("`смешать тест-тест/`", %{}) == "`смешать тест-тест/`"
    end

    test "не автоматически связывает неизвестную задачу" do
      assert project_doc("`смешать фу`", %{}) == "`смешать фу`"
    end

    test "не автоматически связывает справку по неизвестной задаче" do
      assert project_doc("`смешать помощь фу`", %{}) == "`смешать помощь фу`"
    end
  end

  describe "эрланговые функции" do
    test "автоссылки на функции erlang" do
      assert project_doc("`:erlang.apply/2`", %{}) ==
               "[`:erlang.apply/2`](#{@erlang_docs}erlang.html#apply-2)"

      assert project_doc("`:erlang.adler32/2`", %{}) ==
               "[`:erlang.adler32/2`](#{@erlang_docs}erlang.html#adler32-2)"

      assert project_doc("`:erlang.apply/2` `:erlang.apply/3`", %{}) ==
               "[`:erlang.apply/2`](#{@erlang_docs}erlang.html#apply-2) " <>
                 "[`:erlang.apply/3`](#{@erlang_docs}erlang.html#apply-3)"

      assert project_doc("`:erl_prim_loader.get_file/1`", %{}) ==
               "[`:erl_prim_loader.get_file/1`](#{@erlang_docs}erl_prim_loader.html#get_file-1)"

      assert project_doc("`:zlib.deflateInit/2`", %{}) ==
               "[`:zlib.deflateInit/2`](#{@erlang_docs}zlib.html#deflateInit-2)"

      assert project_doc("`:file.change_owner/2,3`", %{}) ==
               "[`:file.change_owner/2,3`](#{@erlang_docs}file.html#change_owner-2)"
    end

    test "автоссылки на функции Erlang с помощью пользовательских ссылок" do
      assert project_doc("[`пример`](`:lists.reverse/1`)", %{}) ==
               "[`example`](#{@erlang_docs}lists.html#reverse-1)"

      assert project_doc("[`пример`](`:lists.reverse/1,2`)", %{}) ==
               "[`example`](#{@erlang_docs}lists.html#reverse-1)"

      assert project_doc("[пример](`:lists.reverse/1`)", %{}) ==
               "[пример](#{@erlang_docs}lists.html#reverse-1)"
    end

    test "не автоматически связывает предварительно связанные документы" do
      assert project_doc("[`:erlang.apply/2`](other.html)", %{}) ==
               "[`:erlang.apply/2`](other.html)"

      assert project_doc("[the `:erlang.apply/2`](other.html)", %{}) ==
               "[the `:erlang.apply/2`](other.html)"

      assert project_doc("[функция `:erlang.apply/2`](`Kernel.apply/2`)", %{}) ==
               "[функция `:erlang.apply/2`](#{@elixir_docs}elixir/Kernel.html#apply/2)"

      assert project_doc("[функция :erlang.apply/2](`Kernel.apply/2`)", %{}) ==
               "[функция :erlang.apply/2](#{@elixir_docs}elixir/Kernel.html#apply/2)"

      assert project_doc("[функция `:erlang.apply/2`](other.html)", %{}) ==
               "[функция `:erlang.apply/2`](other.html)"
    end

    test "не выполняет автолинковку для функций, которые не являются частью дистрибутива erlang" do
      assert project_doc("`:unknown.foo/0`", %{}) == "`:unknown.foo/0`"
    end
  end

  describe "typespecs" do
    test "операторы форматов" do
      assert Autolink.typespec(quote(do: +foo() :: foo()), [], [], []) == ~s[+foo() :: foo()]

      assert Autolink.typespec(quote(do: foo() + foo() :: foo()), [], [], []) ==
               ~s[foo() + foo() :: foo()]
    end

    test "полоски для родителей" do
      assert Autolink.typespec(quote(do: foo({}, bar())), [], []) == ~s[foo({}, bar())]
    end

    test "автоссылки местных жителей" do
      assert Autolink.typespec(quote(do: foo(1)), [foo: 1], []) ==
               ~s[<a href="#т:фу/1">foo</a>(1)]

      assert Autolink.typespec(quote(do: bar(foo(1))), [foo: 1], []) ==
               ~s[bar(<a href="#т:фу/1">foo</a>(1))]

      assert Autolink.typespec(quote(do: (bar(foo(1)) when bat: foo(1))), [foo: 1], []) ==
               ~s[bar(<a href="#т:фу/1">foo</a>(1)) when bat: <a href=\"#t:foo/1\">foo</a>(1)]

      Assert Autolink.typespec(quote(do: bar(foo(1))), [], []) == ~s[bar(foo(1))]
    конец

    тест "autolinks same type and function name" делать
      Assert Autolink.typespec(quote(do: foo() :: foo()), [foo: 0], [], []) ==
               ~s[foo() :: <a href="#t:foo/0">foo</a>()]

      assert Autolink.typespec(quote(do: foo(1) :: foo(1)), [foo: 1], [], []) ==
               ~s[foo(1) :: <a href="#т:фу/1">foo</a>(1)]

      assert Autolink.typespec(quote(do: (foo(1) :: foo(1) when bat: foo(1))), [foo: 1], [], []) ==
               ~s[foo(1) :: <a href=\"#t:foo/1\">foo</a>(1) when bat: <a href=\"#t:foo/1\">foo</a>(1)]

      assert Autolink.typespec(quote(do: bar(foo(1)) :: foo(1)), [foo: 1], [], []) ==
               ~s[bar(<a href=\"#t:foo/1\">foo</a>(1)) :: <a href=\"#t:foo/1\">foo</a>(1)]

      assert Autolink.typespec(quote(do: (bar(f(1)) :: f(1) when bat: f(1))), [f: 1], [], []) ==
               ~s[bar(<a href=\"#t:f/1\">f</a>(1)) :: <a href=\"#t:f/1\">f</a>(1) when bat: <a href=\"#t:f/1\">f</a>(1)]

      assert Autolink.typespec(quote(do: bar(foo :: foo(1)) :: foo(1)), [foo: 1], [], []) ==
               ~s[bar(foo :: <a href=\"#t:foo/1\">foo</a>(1)) :: <a href=\"#t:foo/1\">foo</a>(1)]
    end

    test "autolinks Elixir types" делать
      Assert Autolink.typespec(quote(do: String.t()), [], []) ==
               ~s[<a href="#{@elixir_docs}elixir/String.html#t:t/0">String.t</a>()]

      assert Autolink.typespec(quote(do: Unknown.bar()), [], []) == ~s[Unknown.bar()]
    end

    test "автоссылки Основные типы Эликсира" do
      assert Autolink.typespec(quote(do: atom()), [], []) ==
               ~s[<a href=\"#{@elixir_docs}elixir/typespecs.html#basic-types\">atom</a>()]
    конец

    тест "autolinks Elixir built-in types" do
      assert Autolink.typespec(quote(do: term()), [], []) ==
               ~s[<a href=\"#{@elixir_docs}elixir/typespecs.html#built-in-types\">term</a>()]

      assert Autolink.typespec(quote(do: term()), [], [Kernel]) ==
               ~s[<a href=\"typespecs.html#built-in-types\">term</a>()]
    end

    test "autolinks Erlang types" do
      assert Autolink.typespec(quote(do: :sets.set()), [], []) ==
               ~s[<a href=\"#{@erlang_docs}sets.html#type-set\">:sets.set</a>()]

      assert Autolink.typespec(quote(do: :sets.set(foo())), [], []) ==
               ~s[<a href=\"#{@erlang_docs}sets.html#type-set\">:sets.set</a>(foo())]

      assert Autolink.typespec(quote(do: :sets.set(foo())), [foo: 0], []) ==
               ~s[<a href=\"#{@erlang_docs}sets.html#type-set\">:sets.set</a>(<a href=\"#t:foo/0\">foo</a>())]
    end

    test "autolinks shared aliases" делать
      Assert Autolink.typespec(quote(do: Foo.t()), [], [Foo]) ==
               ~s[<a href="Foo.html#t:t/0">Foo.t</a>()]
    end

    test "автоссылки внутри параметризованных типов" do
      assert Autolink.typespec(quote(do: t(foo())), [t: 1, foo: 0], []) ==
               ~s[<a href="#т:т/1">t</a>(<a href="#т:фу/0">foo</a>())]

      assert Autolink.typespec(quote(do: Parameterized.t(foo())), [foo: 0], [Parameterized]) ==
               ~s[<a href="Параметризованный.html#t:t/1">Parameterized.t</a>(<a href="#т:фу/0">foo</a>())]

      assert Autolink.typespec(quote(do: parameterized_t(Foo.t())), [parameterized_t: 1], [Foo]) ==
               ~s[<a href="#t:parameterized_t/1">parameterized_t</a>(<a href="Foo.html#t:t/0">Foo.t</a>())]

      assert Autolink.typespec(quote(do: Parameterized.t(Foo.t())), [], [Parameterized, Foo]) ==
               ~s[<a href="Параметризованный.html#t:t/1">Parameterized.t</a>(<a href="Foo.html#t:t/0">Foo.t</a>())]

      assert Autolink.typespec(quote(do: t(foo() | bar())), [t: 1, foo: 0, bar: 0], []) ==
               ~s[<a href="#т:т/1">t</a>(<a href="#т:фу/0">foo</a>() | <a href="#т:бар/0">bar</a>())]

      assert Autolink.typespec(quote(do: t(t(foo()))), [t: 1, foo: 0], []) ==
               ~s[<a href="#т:т/1">t</a>(<a href="#т:т/1">t</a>(<a href="#т:фу/0">foo</a>()))]

      assert Autolink.typespec(quote(do: parameterized_t(foo())), [foo: 0], []) ==
               ~s[parameterized_t(<a href="#т:фу/0">foo</a>())]

      assert Autolink.typespec(quote(do: parameterized_t(atom())), [], []) ==
               ~s[parameterized_t(<a href=\"#{@elixir_docs}elixir/typespecs.html#basic-types\">atom</a>())]

      assert Autolink.typespec(quote(do: parameterized_t(atom()) :: list(function())), [], []) ==
               ~s[parameterized_t(<a href=\"#{@elixir_docs}elixir/typespecs.html#basic-types\">atom</a>()) :: ] <>
                 ~s[<a href=\"#{@elixir_docs}elixir/typespecs.html#basic-types\">list</a>(] <>
                 ~s[<a href=\"#{@elixir_docs}elixir/typespecs.html#built-in-types\">function</a>())]
    end

    test "placeholders" делать
      Assert_typespec_placeholders(
        "t()",
        "_p1_()",
        т: 0
      )

      Assert_typespec_placeholders(
        "foobar()",
        "_ppp1_()",
        Фубар: 0
      )

      Assert_typespec_placeholders(
        "Mod.foobar()",
        "_ppppppp1_()",
        [],
        [Мод]
      )

      Assert_typespec_placeholders(
        "foobar(barbaz())",
        "_ppp1_(_ppp2_())",
        Фубар: 1,
        барбаз: 0
      )

      Assert_typespec_placeholders(
        "Mod.foobar(Mod.barbaz())",
        "_ppppppp1_(_ppppppp2_())",
        [],
        [Мод]
      )

      Assert_typespec_placeholders(
        "foobar(foobar(barbaz()))",
        "_ppp1_(_ppp1_(_ppp2_()))",
        Фубар: 1,
        барбаз: 0
      )
    конец
  конец

  описать "corner-cases" делать
    тест "accepts functions around () and []" делать
      утверждать project_doc("`===/2`", %{aliases: [Kernel]}) == "[`===/2`](Kernel.html#===/2)"
      assert project_doc("(`===/2`)", %{aliases: [Kernel]}) == "([`===/2`](Kernel.html#===/2))"
      assert project_doc("[`===/2`]", %{aliases: [Kernel]}) == "[[`===/2`](Kernel.html#===/2)]"
    end

    test "экранируйте специальные символы во фрагментах URL и оставляйте зарезервированные нетронутыми." do
      assert project_doc("`&/1`", %{}) ==
               "[`&/1`](#{@elixir_docs}elixir/Kernel.SpecialForms.html#&/1)"

      assert project_doc("`<<>>/1`", %{}) ==
               "[`<<>>/1`](#{@elixir_docs}elixir/Kernel.SpecialForms.html#%3C%3C%3E%3E/1)"
    end

    test "имеет дело с дополнительным пространством имен Elixir" do
      assert project_doc("`` Эликсир. Перечисление''", %{}) ==
               "[`Elixir.Enum`](#{@elixir_docs}elixir/Enum.html)"

      assert project_doc("``Elixir.Enum.concat/1''", %{}) ==
               "[`Elixir.Enum.concat/1`](#{@elixir_docs}elixir/Enum.html#concat/1)"

      assert project_doc("`t:Elixir.Enum.t/0`", %{}) ==
               "[`Elixir.Enum.t/0`](#{@elixir_docs}elixir/Enum.html#t:t/0)"
    end
  end

  ## Помощники

  defp assert_typespec_placeholders(original, expected, typespecs, aliases \\ []) do
    ast = Code.string_to_quoted!(original)
    {actual, _} = Autolink.format_and_extract_typespec_placeholders(ast, typespecs, aliases, [])
    assert actual == expected, "Исходное: #{original}\nОжидаемое: #{expected}\nФактическое: #{actual}"
  end

  defp project_doc(string, id \\ nil, compiled) do
    Autolink.project_doc(string, id, compiled)
  end
end
