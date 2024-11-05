defmodule Taggart.Tags do
  @moduledoc """
  Define HTML tags.

  Contains macros for creating a tag-based DSL.
  """

  @attr_prefixes [:aria, :data]

  @doc "See `taggart/1`"
  defmacro taggart() do
    quote location: :keep do
      {:safe, ""}
    end
  end

  @doc """
  Allows grouping tags in a block.

  Groups tags such that they all become part of the result. Normally,
  with an Elixir block, only the last expression is part of the value.
  This is useful, for example, as the do block of
  `Phoenix.HTML.Form.form_for/4`.

  ```
  form_for(conn, "/users", [as: :user], fn f ->
    taggart do
      label do
        "Name:"
        text_input(f, :name)
      end
      label do
        "Age:"
        select(f, :age, 18..100)
      end
    end
  end
  ```

  ## Examples

      iex> taggart() |> Phoenix.HTML.safe_to_string()
      ""

      iex> (taggart do div() ; span() end) |> Phoenix.HTML.safe_to_string()
      "<div></div><span></span>"

  """
  defmacro taggart(do: content) do
    content =
      case content do
        {:__block__, _, inner} -> inner
        _ -> content
      end

    quote location: :keep, generated: true do
      content = unquote(content)

      case content do
        # monadically combine array of [{:safe, content}, ...] -> {:safe, [content, ...]}
        clist when is_list(clist) ->
          inners =
            for c <- List.flatten(clist) do
              {:safe, inner} = c
              inner
            end

          {:safe, [inners]}

        {:safe, _} = c ->
          c

        c ->
          Phoenix.HTML.html_escape(c)
      end
    end
  end

  @doc """
  Define a new tag.

  ```
  deftag :span
  deftag :div

  div do
    span("Foo")
  end
  ```
  """
  defmacro deftag(tag) do
    quote location: :keep,
          bind_quoted: [
            tag: Macro.escape(tag, unquote: true)
          ] do
      defmacro unquote(tag)(content_or_attrs \\ [])

      # if called with a variable we have to unquote it to check if its attributes (list) or content
      defmacro unquote(tag)({var_name, metadata, context} = content_or_attrs)
               when is_atom(var_name) and is_list(metadata) and is_atom(context) do
        # push tag down to next quote
        tag = unquote(tag)

        quote location: :keep, generated: true do
          {content, attrs} =
            case unquote(content_or_attrs) do
              attrs when is_list(attrs) -> Keyword.pop(attrs, :do, "")
              content -> {content, []}
            end

          Taggart.Tags.build_tag(unquote(tag), attrs, content)
        end
      end

      defmacro unquote(tag)(attrs)
               when is_list(attrs) do
        # push tag down to next quote
        tag = unquote(tag)
        {content, attrs} = Keyword.pop(attrs, :do, "")

        Taggart.Tags.build_tag_quoted(tag, attrs, content)
      end

      defmacro unquote(tag)(content) do
        # push tag down to next quote
        tag = unquote(tag)
        attrs = Macro.escape([])

        Taggart.Tags.build_tag_quoted(tag, attrs, content)
      end

      @doc """
      Produce a "#{tag}" tag.

      ## Examples

          iex> #{tag}() |> Phoenix.HTML.safe_to_string()
          "<#{tag}></#{tag}>"

          iex> #{tag}("content") |> Phoenix.HTML.safe_to_string()
          "<#{tag}>content</#{tag}>"

          iex> #{tag}("content", class: "foo") |> Phoenix.HTML.safe_to_string()
          "<#{tag} class=\\"foo\\">content</#{tag}>"

          iex> #{tag}() do end |> Phoenix.HTML.safe_to_string()
          "<#{tag}></#{tag}>"

          iex> #{tag}() do "content" end |> Phoenix.HTML.safe_to_string()
          "<#{tag}>content</#{tag}>"

          iex> #{tag}(nil, class: "foo") do "content" end |> Phoenix.HTML.safe_to_string()
          "<#{tag} class=\\"foo\\">content</#{tag}>"

      """
      defmacro unquote(tag)(content, attrs)
               when not is_list(content) do
        tag = unquote(tag)

        Taggart.Tags.build_tag_quoted(tag, attrs, content)
      end

      # Main method
      defmacro unquote(tag)(attrs, do: content) do
        tag = unquote(tag)

        Taggart.Tags.build_tag_quoted(tag, attrs, content)
      end

      # Keep below the main method above, otherwise macro expansion loops forever
      defmacro unquote(tag)(content, attrs) when is_list(attrs) do
        tag = unquote(tag)

        Taggart.Tags.build_tag_quoted(tag, attrs, content)
      end

      # three arg form to be used in rare cases where the one arg form cannot determine the correct type (content/attrs)
      defmacro unquote(tag)(_ignored, attrs, do: content) do
        tag = unquote(tag)

        Taggart.Tags.build_tag_quoted(tag, attrs, content)
      end
    end
  end

  @doc """
  Define a new void tag.

  ```
  deftag :hr, void: true
  deftag :img, void: true

  hr()
  img(class: "red")
  ```
  """
  defmacro deftag(tag, void: true) do
    quote location: :keep,
          bind_quoted: [
            tag: Macro.escape(tag, unquote: true)
          ] do
      @doc """
      Produce a void "#{tag}" tag.

      ## Examples

          iex> #{tag}() |> Phoenix.HTML.safe_to_string()
          "<#{tag}>"

          iex> #{tag}(class: "foo") |> Phoenix.HTML.safe_to_string()
          "<#{tag} class=\\"foo\\">"
      """
      defmacro unquote(tag)(attrs \\ []) do
        tag = unquote(tag)

        quote location: :keep do
          Taggart.Tags.build_tag(unquote(tag), unquote(attrs))
        end
      end
    end
  end

  def build_tag_quoted(tag, attrs, content) do
    content =
      case content do
        {:__block__, _, inner} -> inner
        _ -> content
      end

    quote location: :keep do
      Taggart.Tags.build_tag(unquote(tag), unquote(attrs), unquote(content))
    end
  end

  def build_tag(tag, attrs) do
    name = to_string(tag)
    {:safe, [?<, name, Taggart.Tags.build_attrs(name, attrs), ?>]}
  end

  def build_tag(tag, attrs, content) do
    {:safe, escaped} = Phoenix.HTML.html_escape(content)

    name = to_string(tag)
    {:safe, [?<, name, Taggart.Tags.build_attrs(name, attrs), ?>, escaped, ?<, ?/, name, ?>]}
  end

  def build_attrs(_tag, []), do: []
  def build_attrs(tag, attrs), do: build_attrs(tag, attrs, [])

  def build_attrs(_tag, [], acc) do
    acc |> Enum.sort() |> tag_attrs
  end

  def build_attrs(tag, [{k, v} | t], acc) when k in @attr_prefixes and is_list(v) do
    build_attrs(tag, t, nested_attrs(dasherize(k), v, acc))
  end

  def build_attrs(tag, [{k, true} | t], acc) do
    build_attrs(tag, t, [{dasherize(k)} | acc])
  end

  def build_attrs(tag, [{_, false} | t], acc) do
    build_attrs(tag, t, acc)
  end

  def build_attrs(tag, [{_, nil} | t], acc) do
    build_attrs(tag, t, acc)
  end

  def build_attrs(tag, [{k, v} | t], acc) do
    build_attrs(tag, t, [{dasherize(k), v} | acc])
  end

  defp dasherize(value) when is_atom(value), do: dasherize(Atom.to_string(value))
  defp dasherize(value) when is_binary(value), do: String.replace(value, "_", "-")

  defp tag_attrs([]), do: []

  defp tag_attrs(attrs) do
    for a <- attrs do
      case a do
        {k, v} -> [?\s, k, ?=, ?", attr_escape(v), ?"]
        {k} -> [?\s, k]
      end
    end
  end

  defp attr_escape({:safe, data}),
    do: data

  defp attr_escape(nil),
    do: []

  # When passing a list to an attribue it gets joined with " ".
  # This is useful for setting multiple classes like: `class: ~w(first second)`
  # It is sensible to allow this for all attributes, since css has a special syntax for accessing
  # white space-separated values. See: https://www.w3.org/TR/CSS2/selector.html#x16
  defp attr_escape(list) when is_list(list) do
    # Since this gets converted to IO data anyway it is cheaper to intersperse the joiner rather than
    # calling Enum.join/2, which reverses the list after after joining and then converts it to binary.
    list |> Enum.intersperse(" ") |> Phoenix.HTML.Safe.to_iodata()
  end

  defp attr_escape(other),
    do: Phoenix.HTML.Safe.to_iodata(other)

  defp nested_attrs(attr, dict, acc) do
    Enum.reduce(dict, acc, fn {k, v}, acc ->
      attr_name = "#{attr}-#{dasherize(k)}"

      case is_list(v) do
        true -> nested_attrs(attr_name, v, acc)
        false -> [{attr_name, v} | acc]
      end
    end)
  end
end
