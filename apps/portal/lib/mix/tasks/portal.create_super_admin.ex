defmodule Mix.Tasks.Portal.CreateSuperAdmin do
  @moduledoc """
  Creates a super admin user account.

  ## Usage

      mix portal.create_super_admin email@example.com

  The password will be prompted interactively.
  """
  use Mix.Task

  @shortdoc "Creates a super admin user account"

  @impl Mix.Task
  def run([email]) do
    Mix.Task.run("app.start")

    password =
      Mix.shell().prompt("Enter password (min 12 characters): ")
      |> String.trim()

    case Portal.Accounts.create_super_admin(%{email: email, password: password}) do
      {:ok, user} ->
        Mix.shell().info("Super admin created: #{user.email}")

      {:error, changeset} ->
        Mix.shell().error("Failed to create super admin:")

        Ecto.Changeset.traverse_errors(changeset, &interpolate_error/1)
        |> Enum.each(fn {field, errors} ->
          Mix.shell().error("  #{field}: #{Enum.join(errors, ", ")}")
        end)
    end
  end

  def run(_) do
    Mix.shell().error("Usage: mix portal.create_super_admin email@example.com")
  end

  defp interpolate_error({msg, opts}) do
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end
