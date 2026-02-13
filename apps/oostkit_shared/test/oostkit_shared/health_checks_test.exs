defmodule OostkitShared.HealthChecksTest do
  use ExUnit.Case, async: true

  alias OostkitShared.HealthChecks

  describe "check_process/1" do
    test "returns :ok for a running process" do
      assert HealthChecks.check_process(:kernel_sup) == :ok
    end

    test "returns :error for a non-existent process" do
      assert HealthChecks.check_process(:nonexistent_process_name) == :error
    end
  end
end
