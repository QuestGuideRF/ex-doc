defmodule ExDoc.GroupMatcherTest do
  use ExUnit.Case, async: true
  import ExDoc.GroupMatcher

  describe "соответствие модулей" do
    test "он может сопоставлять модули по именам их атомов" do
      patterns = [
        Group: [MyApp.SomeModule, :lists]
      ]

      assert match_module(patterns, MyApp.SomeModule, "MyApp.SomeModule") == :Group
      assert match_module(patterns, :lists, ":lists") == :Group
      assert match_module(patterns, MyApp.SomeOtherModule, "MyApp.SomeOtherModule") == nil
    end

    test "он может сопоставлять модули по их строковым именам" do
      patterns = [
        Group: ["MyApp.SomeModule", ":lists"]
      ]

      assert match_module(patterns, MyApp.SomeModule, "MyApp.SomeModule") == :Group
      assert match_module(patterns, :lists, ":lists") == :Group
      assert match_module(patterns, MyApp.SomeOtherModule, "MyApp.SomeOtherModule") == nil
    end

    test "он может сопоставлять модули с помощью регулярных выражений" do
      patterns = [
        Group: ~r/MyApp\..?/
      ]

      assert match_module(patterns, MyApp.SomeModule, "MyApp.SomeModule") == :Group
      assert match_module(patterns, MyApp.SomeOtherModule, "MyApp.SomeOtherModule") == :Group
      assert match_module(patterns, MyAppWeb.SomeOtherModule, "MyAppWeb.SomeOtherModule") == nil
    end
  end

  describe "соответствие дополнительных услуг" do
    test "он может сопоставлять дополнительные файлы по их строковым именам" do
      patterns = [
        Group: ["docs/handling/testing.md"]
      ]

      assert match_extra(patterns, "docs/handling/testing.md") == :Group
      assert match_extra(patterns, "docs/handling/setup.md") == nil
    end

    test "он может сопоставлять дополнительные файлы с помощью регулярных выражений" do
      patterns = [
        Group: ~r/docs\/handling?/
      ]

      assert match_extra(patterns, "docs/handling/testing.md") == :Group
      assert match_extra(patterns, "docs/handling/setup.md") == :Group
      assert match_extra(patterns, "docs/introduction.md") == nil
    end
  end
end
