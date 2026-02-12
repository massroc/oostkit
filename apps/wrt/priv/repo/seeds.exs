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
alias Wrt.Platform.{Organisation, SuperAdmin}
alias Wrt.TenantManager

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

  # Create a dev organisation matching the PortalAuth dev bypass email
  case Repo.get_by(Organisation, admin_email: "dev@oostkit.local") do
    nil ->
      org =
        %Organisation{}
        |> Organisation.registration_changeset(%{
          name: "Dev Organisation",
          admin_name: "Dev Admin",
          admin_email: "dev@oostkit.local"
        })
        |> Ecto.Changeset.put_change(:status, "approved")
        |> Ecto.Changeset.put_change(
          :approved_at,
          DateTime.utc_now() |> DateTime.truncate(:second)
        )
        |> Repo.insert!()

      {:ok, _} = TenantManager.create_tenant(org.id)

      IO.puts("Created dev organisation: #{org.name} (#{org.slug}) with tenant schema")

    _existing ->
      IO.puts("Dev organisation already exists")
  end
end
