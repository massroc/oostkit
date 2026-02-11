defmodule PortalWeb.ComingSoonLive do
  use PortalWeb, :live_view

  alias Portal.Marketing

  @impl true
  def mount(params, _session, socket) do
    changeset = Marketing.change_interest_signup()

    {:ok,
     socket
     |> assign(:context, params["context"])
     |> assign(:tool_name, params["name"])
     |> assign(:submitted, false)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:context, params["context"])
     |> assign(:tool_name, params["name"])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen">
      <div class="mx-auto max-w-lg px-6 py-20 sm:px-8">
        <div class="text-center">
          <h1 class="text-3xl font-bold tracking-tight text-text-dark">
            {heading(@context, @tool_name)}
          </h1>
          <p class="mt-4 text-lg text-zinc-600">
            {subtext(@context)}
          </p>
        </div>

        <%= if @submitted do %>
          <div class="mt-10 rounded-xl border border-ok-green-200 bg-ok-green-50 p-8 text-center">
            <.icon name="hero-check-circle" class="mx-auto h-10 w-10 text-ok-green-600" />
            <p class="mt-4 text-lg font-medium text-ok-green-800">
              Thanks! We'll be in touch.
            </p>
          </div>
        <% else %>
          <div class="mt-10 rounded-xl border border-zinc-200 bg-surface-sheet p-8 shadow-sheet">
            <.simple_form for={@form} phx-submit="submit" phx-change="validate">
              <.input field={@form[:name]} label="Name" placeholder="Your name" />
              <.input field={@form[:email]} type="email" label="Email" placeholder="you@example.com" required />
              <:actions>
                <.button type="submit" class="w-full">
                  Keep me posted
                </.button>
              </:actions>
            </.simple_form>
          </div>
        <% end %>

        <div class="mt-8 text-center">
          <.link navigate={~p"/home"} class="text-sm text-ok-purple-600 hover:text-ok-purple-800">
            &larr; Back to tools
          </.link>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"interest_signup" => params}, socket) do
    changeset =
      Marketing.change_interest_signup(%Portal.Marketing.InterestSignup{}, params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("submit", %{"interest_signup" => params}, socket) do
    params = Map.put(params, "context", signup_context(socket.assigns.context, socket.assigns.tool_name))

    case Marketing.create_interest_signup(params) do
      {:ok, _signup} ->
        {:noreply, assign(socket, :submitted, true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: "interest_signup"))
  end

  defp heading("signup", _), do: "Sign up is coming soon"
  defp heading("login", _), do: "Login is coming soon"
  defp heading("tool", name) when is_binary(name), do: "#{name} is coming soon"
  defp heading(_, _), do: "More tools are on the way"

  defp subtext("signup"), do: "We're getting ready for our first users."
  defp subtext("login"), do: "We're getting ready for our first users."
  defp subtext("tool"), do: "We're still building this one."
  defp subtext(_), do: "We're building new tools all the time. Be the first to know."

  defp signup_context(context, tool_name) do
    case {context, tool_name} do
      {"tool", name} when is_binary(name) -> "tool:#{name}"
      {ctx, _} when is_binary(ctx) -> ctx
      _ -> "general"
    end
  end
end
