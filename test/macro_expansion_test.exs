defmodule MacroExpansionTest do
  use Taggart.ConnCase
  use Taggart.HTML

  defmacrop content_tag_ast(params) do
    quote do
      {{:., _, [{:__aliases__, _, [:Taggart, :Tags]}, :build_tag]}, _metadata, unquote(params)}
    end
  end

  test "basic ast" do
    expanded =
      quote location: :keep do
        div(class: "foo", id: "bar") do
          "content"
        end
      end

    assert {:div, _, [[class: "foo", id: "bar"], [do: "content"]]} = expanded
  end

  test "desugar div/1 (attrs)" do
    expanded =
      quote location: :keep do
        div(id: "bar")
      end
      |> Macro.expand_once(__ENV__)

    assert content_tag_ast([:div, [id: "bar"], ""]) = expanded
  end

  test "desugar div/1 (content)" do
    expanded =
      quote location: :keep do
        div("content")
      end
      |> Macro.expand_once(__ENV__)

    assert content_tag_ast([:div, [], "content"]) = expanded
  end

  test "desugar div/1 tag(attrs ++ do_arg)" do
    expanded =
      quote location: :keep do
        div(id: "bar", do: "do_arg")
      end
      |> Macro.expand_once(__ENV__)

    assert content_tag_ast([:div, [id: "bar"], "do_arg"]) = expanded
  end

  test "desugar div/1 tag(do: content)" do
    expanded =
      quote location: :keep do
        div do
          "content"
        end
      end
      |> Macro.expand_once(__ENV__)

    assert content_tag_ast([:div, [], "content"]) = expanded
  end

  test "desugar div/2, (content, attrs)" do
    expanded =
      quote location: :keep do
        div("content", do: "do_arg", id: "bar")
      end
      |> Macro.expand_once(__ENV__)

    assert content_tag_ast([:div, [do: "do_arg", id: "bar"], "content"]) = expanded
  end

  test "desugar div/2, (content, do_arg)" do
    expanded =
      quote location: :keep do
        div("content", do: "do_arg")
      end
      |> Macro.expand_once(__ENV__)

    assert content_tag_ast([:div, [do: "do_arg"], "content"]) = expanded
  end

  test "desugar div/1 (attrs, do: content)" do
    expanded =
      quote location: :keep do
        div(id: "bar") do
          "content"
        end
      end
      |> Macro.expand_once(__ENV__)

    assert content_tag_ast([:div, [id: "bar"], "content"]) = expanded
  end

  test "desugar div/1 (content_or_attrs) as var" do
    # the var doesn't actually have to exist
    expanded =
      quote location: :keep do
        div(content_or_attrs_var)
      end
      |> Macro.expand_once(__ENV__)

    # just check that it expands to a block that eventually calls the content_tag function
    assert {:__block__, _, [_case_assignment, content_tag_ast([:div, _, _])]} = expanded
  end
end
