defmodule Portal.Tools.Tool do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "tools" do
    field :name, :string
    field :tagline, :string
    field :description, :string
    field :url, :string
    field :audience, :string
    field :default_status, :string, default: "coming_soon"
    field :admin_enabled, :boolean, default: true
    field :sort_order, :integer

    timestamps()
  end

  def changeset(tool, attrs) do
    tool
    |> cast(attrs, [
      :id,
      :name,
      :tagline,
      :description,
      :url,
      :audience,
      :default_status,
      :admin_enabled,
      :sort_order
    ])
    |> validate_required([:id, :name, :tagline, :audience, :default_status, :sort_order])
    |> validate_inclusion(:audience, ~w(facilitator team))
    |> validate_inclusion(:default_status, ~w(live coming_soon))
    |> unique_constraint(:sort_order)
  end

  @doc """
  Returns the effective status considering both default_status and admin_enabled.
  """
  def effective_status(%__MODULE__{default_status: "coming_soon"}), do: :coming_soon
  def effective_status(%__MODULE__{admin_enabled: false}), do: :maintenance
  def effective_status(%__MODULE__{default_status: "live", admin_enabled: true}), do: :live
end
