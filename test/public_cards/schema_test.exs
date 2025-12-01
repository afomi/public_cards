defmodule PublicCards.SchemaTest do
  use ExUnit.Case, async: false

  alias PublicCards.Schema

  # Give the GenServer time to load the schema
  setup do
    # Wait for schema to be loaded
    Process.sleep(100)
    :ok
  end

  describe "get_type/1" do
    test "returns Person type" do
      assert {:ok, type} = Schema.get_type("schema:Person")
      assert type.id == "schema:Person"
      assert type.label == "Person"
      assert is_binary(type.comment)
    end

    test "returns Organization type" do
      assert {:ok, type} = Schema.get_type("schema:Organization")
      assert type.id == "schema:Organization"
      assert type.label == "Organization"
    end

    test "returns error for unknown type" do
      assert {:error, :not_found} = Schema.get_type("schema:NotARealType")
    end
  end

  describe "get_property/1" do
    test "returns name property" do
      assert {:ok, prop} = Schema.get_property("schema:name")
      assert prop.id == "schema:name"
      assert prop.label == "name"
    end

    test "returns email property" do
      assert {:ok, prop} = Schema.get_property("schema:email")
      assert prop.id == "schema:email"
    end

    test "returns error for unknown property" do
      assert {:error, :not_found} = Schema.get_property("schema:notAProperty")
    end
  end

  describe "list_types/0" do
    test "returns all Schema.org types" do
      types = Schema.list_types()
      assert is_list(types)
      # Should include highlighted types
      assert "schema:Person" in types
      assert "schema:Organization" in types
      # Should also include many more types from the full vocabulary
      assert length(types) > 100
    end
  end

  describe "list_highlighted_types/0" do
    test "returns curated subset of types" do
      types = Schema.list_highlighted_types()
      assert is_list(types)
      assert "schema:Person" in types
      assert "schema:Organization" in types
      assert "schema:GovernmentOrganization" in types
      assert "schema:Place" in types
      assert "schema:Role" in types
      assert "schema:ContactPoint" in types
      # Should be limited to the curated set
      assert length(types) == 6
    end
  end

  describe "search_types/1" do
    test "finds types by label" do
      results = Schema.search_types("Person")
      assert is_list(results)
      assert "schema:Person" in results
    end

    test "search is case-insensitive" do
      results = Schema.search_types("person")
      assert "schema:Person" in results
    end

    test "returns empty list for no matches" do
      results = Schema.search_types("xyznotarealtype123")
      assert results == []
    end
  end

  describe "get_properties_for_type/1" do
    test "returns properties for Person" do
      assert {:ok, properties} = Schema.get_properties_for_type("schema:Person")
      assert is_list(properties)
      # Person should have name, email, etc.
      assert "schema:name" in properties or "schema:givenName" in properties
    end

    test "includes inherited properties from Thing" do
      assert {:ok, properties} = Schema.get_properties_for_type("schema:Person")
      # Thing properties should be inherited
      # (name, description, url are on Thing)
      assert length(properties) > 0
    end

    test "returns error for unknown type" do
      assert {:error, :type_not_found} = Schema.get_properties_for_type("schema:FakeType")
    end
  end

  describe "valid_property?/2" do
    test "returns true for valid Person property" do
      # jobTitle is specifically on Person
      assert Schema.valid_property?("schema:Person", "schema:jobTitle")
    end

    test "returns false for invalid property" do
      assert Schema.valid_property?("schema:Person", "schema:notARealProperty") == false
    end

    test "returns false for unknown type" do
      assert Schema.valid_property?("schema:FakeType", "schema:name") == false
    end
  end

  describe "highlighted_types/0" do
    test "returns the list of highlighted type IDs" do
      types = Schema.highlighted_types()
      assert is_list(types)
      assert "schema:Person" in types
      assert "schema:Organization" in types
      assert "schema:GovernmentOrganization" in types
      assert "schema:Place" in types
      assert "schema:Role" in types
      assert "schema:ContactPoint" in types
    end
  end
end
