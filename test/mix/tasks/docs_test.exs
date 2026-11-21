Mix.start()
Mix.shell(Mix.Shell.Process)

defmodule Mix.Tasks.DocsTest do
  # Невозможно работать одновременно из-за вызовов Mix compile/deps
  use ExUnit.Case

  def run(args, opts) do
    Mix.Tasks.Docs.run(args, opts, &{&1, &2, &3})
  end

  test "inflects values from app and version" do
    assert [{"ex_doc", "0.1.0", [formatter: "html", deps: _, source_beam: _]}] =
             run([], app: :ex_doc, version: "0.1.0")
  end

  test "принимает несколько форматтеров из CLI" do
    assert [
             {"ex_doc", "0.1.0", [formatter: "html", deps: _, source_beam: _]},
             {"ex_doc", "0.1.0", [formatter: "epub", deps: _, source_beam: _]}
           ] = run(["-f", "html", "-f", "epub"], app: :ex_doc, version: "0.1.0")
  end

  test "принимает несколько форматтеров из конфигурации" do
    assert [
             {"ex_doc", "0.1.0", [formatter: "html", deps: _, source_beam: _, formatters: _]},
             {"ex_doc", "0.1.0", [formatter: "epub", deps: _, source_beam: _, formatters: _]}
           ] = run([], app: :ex_doc, version: "0.1.0", docs: [formatters: ["html", "epub"]])
  end

  test "использует данное имя" do
    assert [{"ExDoc", "0.1.0", [formatter: "html", deps: _, source_beam: _]}] =
             run([], app: :ex_doc, version: "0.1.0", name: "ExDoc")
  end

  test "принимает модули в :main" do
    assert [{"ex_doc", "dev", [formatter: "html", deps: _, main: "Sample", source_beam: _]}] =
             run([], app: :ex_doc, docs: [main: Sample])
  end

  test "принимает файлы в :main" do
    assert [{"ex_doc", "dev", [formatter: "html", deps: _, source_beam: _, main: "another"]}] =
             run([], app: :ex_doc, docs: [main: "another"])
  end

  test "принимает вывод в :output" do
    assert [{"ex_doc", "dev", [formatter: "html", deps: _, source_beam: _, output: "hello"]}] =
             run([], app: :ex_doc, docs: [output: "hello"])
  end

  test "анализирует вывод с меньшим предпочтением, чем у параметров" do
    assert [{"ex_doc", "dev", [formatter: "html", deps: _, source_beam: _, output: "world"]}] =
             run(~w(-o world), app: :ex_doc, docs: [output: "world"])
  end

  test "включает зависимости" do
    assert [{"ex_doc", "dev", [formatter: "html", deps: deps, source_beam: _]}] =
             run([], app: :ex_doc, docs: [])

    assert List.keyfind(deps, Application.app_dir(:earmark), 0) ==
             {Application.app_dir(:earmark),
              "https://hexdocs.pm/earmark/#{Application.spec(:earmark, :vsn)}/"}
  end

  test "позволяет настраивать пути зависимостей" do
    assert [{"ex_doc", "dev", [formatter: "html", deps: deps, source_beam: _]}] =
             run([], app: :ex_doc, docs: [deps: [earmark: "foo"]])

    assert List.keyfind(deps, Application.app_dir(:earmark), 0) ==
             {Application.app_dir(:earmark), "foo"}
  end

  test "принимает ленивые документы" do
    assert [{"ex_doc", "dev", [formatter: "html", deps: _, source_beam: _, main: "another"]}] =
             run([], app: :ex_doc, docs: fn -> [main: "another"] end)
  end

  test "принимает параметры от root" do
    # допустимые параметры: `app`, `name`, `source_url`, `homepage_url`, `version`
    assert [
             {"ExDoc", "1.2.3-dev",
              [
                formatter: "html",
                deps: _,
                source_beam: _,
                homepage_url: "http://elixir-lang.org",
                source_url: "https://github.com/elixir-lang/ex_doc"
              ]}
           ] =
             run([],
               app: :ex_doc,
               name: "ExDoc",
               source_url: "https://github.com/elixir-lang/ex_doc",
               homepage_url: "http://elixir-lang.org",
               version: "1.2.3-dev"
             )

    assert [{"ex_doc", "dev", _}] = run([], app: :ex_doc)
  end

  test "поддерживает зонтичный проект" do
    Mix.Project.in_project(:umbrella, "test/fixtures/umbrella", fn _mod ->
      [
        {"umbrella", "dev",
         [
           formatter: "html",
           deps: _,
           source_beam: _
         ]}
      ] = run([], app: :umbrella, apps_path: "apps/", docs: [])
    end)
  end

  test "поддерживает зонтичный проект с ignore_apps" do
    Mix.Project.in_project(:umbrella, "test/fixtures/umbrella", fn _mod ->
      [
        {"umbrella", "dev",
         [
           formatter: "html",
           deps: _,
           source_beam: _,
           ignore_apps: [:foo]
         ]}
      ] = run([], app: :umbrella, apps_path: "apps/", docs: [ignore_apps: [:foo]])
    end)
  end
end
