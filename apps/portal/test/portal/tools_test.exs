defmodule Portal.ToolsTest do
  use Portal.DataCase, async: true

  alias Portal.Tools
  alias Portal.Tools.Tool

  @valid_attrs %{
    id: "test_tool",
    name: "Test Tool",
    tagline: "A test tool",
    audience: "team",
    default_status: "live",
    sort_order: 99
  }

  describe "list_tools/0" do
    test "returns tools ordered by sort_order" do
      {:ok, _} = Tools.create_tool(%{@valid_attrs | id: "tool_b", sort_order: 98})
      {:ok, _} = Tools.create_tool(%{@valid_attrs | id: "tool_a", sort_order: 97})

      tools = Tools.list_tools()
      assert [%{id: "tool_a"}, %{id: "tool_b"}] = tools
    end

    test "returns empty list when no tools" do
      assert [] == Tools.list_tools()
    end
  end

  describe "get_tool/1" do
    test "returns tool by id" do
      {:ok, tool} = Tools.create_tool(@valid_attrs)
      assert Tools.get_tool(tool.id) == tool
    end

    test "returns nil for non-existent tool" do
      assert Tools.get_tool("nonexistent") == nil
    end
  end

  describe "create_tool/1" do
    test "creates a tool with valid attrs" do
      assert {:ok, tool} = Tools.create_tool(@valid_attrs)
      assert tool.id == "test_tool"
      assert tool.name == "Test Tool"
      assert tool.audience == "team"
      assert tool.default_status == "live"
    end

    test "fails with missing required fields" do
      assert {:error, changeset} = Tools.create_tool(%{})
      assert errors_on(changeset).id
      assert errors_on(changeset).name
      assert errors_on(changeset).tagline
    end

    test "validates audience values" do
      assert {:error, changeset} = Tools.create_tool(%{@valid_attrs | audience: "invalid"})
      assert errors_on(changeset).audience
    end

    test "validates default_status values" do
      assert {:error, changeset} = Tools.create_tool(%{@valid_attrs | default_status: "invalid"})
      assert errors_on(changeset).default_status
    end
  end

  describe "upsert_tool/1" do
    test "inserts new tool" do
      assert {:ok, tool} = Tools.upsert_tool(@valid_attrs)
      assert tool.name == "Test Tool"
    end

    test "updates existing tool on conflict" do
      {:ok, _} = Tools.create_tool(@valid_attrs)
      assert {:ok, tool} = Tools.upsert_tool(%{@valid_attrs | name: "Updated Tool"})
      assert tool.name == "Updated Tool"
    end
  end

  describe "toggle_admin_enabled/1" do
    test "disables an enabled tool" do
      {:ok, tool} = Tools.create_tool(@valid_attrs)
      assert tool.admin_enabled == true

      {:ok, toggled} = Tools.toggle_admin_enabled(tool)
      assert toggled.admin_enabled == false
    end

    test "enables a disabled tool" do
      {:ok, tool} = Tools.create_tool(Map.put(@valid_attrs, :admin_enabled, false))
      assert tool.admin_enabled == false

      {:ok, toggled} = Tools.toggle_admin_enabled(tool)
      assert toggled.admin_enabled == true
    end
  end

  describe "Tool.effective_status/1" do
    test "returns :live for live and enabled tools" do
      tool = %Tool{default_status: "live", admin_enabled: true}
      assert Tool.effective_status(tool) == :live
    end

    test "returns :coming_soon for coming_soon tools regardless of admin_enabled" do
      tool = %Tool{default_status: "coming_soon", admin_enabled: true}
      assert Tool.effective_status(tool) == :coming_soon

      tool = %Tool{default_status: "coming_soon", admin_enabled: false}
      assert Tool.effective_status(tool) == :coming_soon
    end

    test "returns :maintenance for live but disabled tools" do
      tool = %Tool{default_status: "live", admin_enabled: false}
      assert Tool.effective_status(tool) == :maintenance
    end
  end
end
