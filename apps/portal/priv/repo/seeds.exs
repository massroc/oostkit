# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Tools are seeded by migration (20260211223607_seed_tools).

# Dev super admin (idempotent)
alias Portal.Accounts

dev_admin_email = "admin@oostkit.local"

unless Accounts.get_user_by_email(dev_admin_email) do
  {:ok, user} =
    Accounts.create_super_admin(%{email: dev_admin_email, password: "password123456"})

  user
  |> Ecto.Changeset.change(%{name: "Dev Admin"})
  |> Portal.Repo.update!()

  IO.puts("Seeded dev super admin: #{dev_admin_email}")
end
