defmodule WorkgroupPulse.Workshops do
  @moduledoc """
  The Workshops context.

  This context manages workshop templates and their questions.
  It provides the content and structure for running workshops.
  """

  import Ecto.Query, warn: false

  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Workshops.{Question, Template}

  ## Templates

  @doc """
  Returns the list of templates.

  ## Examples

      iex> list_templates()
      [%Template{}, ...]

  """
  def list_templates do
    Repo.all(Template)
  end

  @doc """
  Gets a single template.

  Raises `Ecto.NoResultsError` if the Template does not exist.

  ## Examples

      iex> get_template!(123)
      %Template{}

      iex> get_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_template!(id), do: Repo.get!(Template, id)

  @doc """
  Gets a single template by slug.

  Returns nil if the Template does not exist.

  ## Examples

      iex> get_template_by_slug("six-criteria")
      %Template{}

      iex> get_template_by_slug("non-existent")
      nil

  """
  def get_template_by_slug(slug) do
    Repo.get_by(Template, slug: slug)
  end

  @doc """
  Gets a template with its questions preloaded.

  ## Examples

      iex> get_template_with_questions(123)
      %Template{questions: [%Question{}, ...]}

  """
  def get_template_with_questions(id) do
    Template
    |> Repo.get!(id)
    |> Repo.preload(questions: from(q in Question, order_by: q.index))
  end

  ## Questions

  @doc """
  Returns the list of questions for a template, ordered by index.

  ## Examples

      iex> list_questions(template)
      [%Question{}, ...]

  """
  def list_questions(%Template{} = template) do
    Question
    |> where([q], q.template_id == ^template.id)
    |> order_by([q], q.index)
    |> Repo.all()
  end

  @doc """
  Gets a single question by template and index.

  Returns nil if the Question does not exist.

  ## Examples

      iex> get_question(template, 0)
      %Question{}

      iex> get_question(template, 99)
      nil

  """
  def get_question(%Template{} = template, index) do
    Repo.get_by(Question, template_id: template.id, index: index)
  end

  @doc """
  Gets the count of questions for a template.

  ## Examples

      iex> count_questions(template)
      8

  """
  def count_questions(%Template{} = template) do
    Question
    |> where([q], q.template_id == ^template.id)
    |> Repo.aggregate(:count)
  end
end
