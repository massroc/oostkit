# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Wrt.Repo.insert!(%Wrt.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Wrt.Repo
alias Wrt.Platform.SuperAdmin

# Create a default super admin for development
if Mix.env() == :dev do
  case Repo.get_by(SuperAdmin, email: "admin@example.com") do
    nil ->
      %SuperAdmin{}
      |> SuperAdmin.changeset(%{
        name: "Admin",
        email: "admin@example.com",
        password: "password123"
      })
      |> Repo.insert!()

      IO.puts("Created default super admin: admin@example.com / password123")

    _existing ->
      IO.puts("Super admin already exists")
  end
end
