defmodule ExDoc.Markdown.EarmarkTest do
  use ExUnit.Case, async: true

  alias ExDoc.Markdown.Earmark, as: Markdown

  @moduletag :earmark

  test "to_html генерировать HTML из уценки" do
    assert Markdown.to_html("# Тест\n\nПривет", []) =~ ~s(<h1>Test</h1>\n<p>Hello</p>)
  end

  test "to_html обрабатывает пустой ввод" do
    assert Markdown.to_html("", []) == ""
  end

  test "to_html does not generate smart quotes by default" do
    assert Markdown.to_html("\"привет\"", []) =~ ""привет";"
  end
end
