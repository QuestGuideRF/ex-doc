defmodule ExDoc.Markdown.CmarkTest do
  use ExUnit.Case, async: true

  @moduletag :cmark

  alias ExDoc.Markdown.Cmark, as: Markdown

  test "to_html генерировать HTML из уценки" do
    assert Markdown.to_html("# Тест\n\nПривет", []) =~ ~s(<h1>Test</h1>\n<p>Hello</p>)
  end

  test "to_html обрабатывает пустой ввод" do
    assert Markdown.to_html("", []) == ""
  end
end
