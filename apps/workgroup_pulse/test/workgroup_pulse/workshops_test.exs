defmodule WorkgroupPulse.WorkshopsTest do
  use WorkgroupPulse.DataCase, async: true

  alias WorkgroupPulse.Repo
  alias WorkgroupPulse.Workshops
  alias WorkgroupPulse.Workshops.{Question, Template}

  describe "templates" do
    test "get_template!/1 returns the template with given id" do
      template = Repo.insert!(%Template{name: "Test", slug: "test-get", version: "1.0.0"})
      assert Workshops.get_template!(template.id).id == template.id
    end

    test "get_template_by_slug/1 returns the template with given slug" do
      template = Repo.insert!(%Template{name: "Test", slug: "test-slug", version: "1.0.0"})
      assert Workshops.get_template_by_slug("test-slug").id == template.id
    end

    test "get_template_by_slug/1 returns nil for non-existent slug" do
      assert Workshops.get_template_by_slug("non-existent") == nil
    end

    test "list_templates/0 returns all templates" do
      template = Repo.insert!(%Template{name: "Test", slug: "test-list", version: "1.0.0"})
      assert Workshops.list_templates() == [template]
    end
  end

  describe "questions" do
    setup do
      template =
        Repo.insert!(%Template{
          name: "Test",
          slug: "test-q-#{System.unique_integer()}",
          version: "1.0.0"
        })

      %{template: template}
    end

    test "list_questions/1 returns questions for a template in order", %{template: template} do
      Repo.insert!(%Question{
        template_id: template.id,
        index: 1,
        title: "Q2",
        criterion_number: "2",
        criterion_name: "C2",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        explanation: "Test"
      })

      Repo.insert!(%Question{
        template_id: template.id,
        index: 0,
        title: "Q1",
        criterion_number: "1",
        criterion_name: "C1",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        explanation: "Test"
      })

      Repo.insert!(%Question{
        template_id: template.id,
        index: 2,
        title: "Q3",
        criterion_number: "3",
        criterion_name: "C3",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        explanation: "Test"
      })

      questions = Workshops.list_questions(template)
      assert length(questions) == 3
      assert Enum.map(questions, & &1.index) == [0, 1, 2]
    end

    test "get_question/2 returns the question at given index", %{template: template} do
      question =
        Repo.insert!(%Question{
          template_id: template.id,
          index: 0,
          title: "Q1",
          criterion_number: "1",
          criterion_name: "C1",
          scale_type: "balance",
          scale_min: -5,
          scale_max: 5,
          explanation: "Test"
        })

      assert Workshops.get_question(template, 0).id == question.id
    end

    test "get_question/2 returns nil for non-existent index", %{template: template} do
      assert Workshops.get_question(template, 99) == nil
    end
  end

  describe "get_template_with_questions/1" do
    test "returns template with preloaded questions" do
      template =
        Repo.insert!(%Template{
          name: "Full",
          slug: "full-#{System.unique_integer()}",
          version: "1.0.0"
        })

      Repo.insert!(%Question{
        template_id: template.id,
        index: 0,
        title: "Q1",
        criterion_number: "1",
        criterion_name: "C1",
        scale_type: "balance",
        scale_min: -5,
        scale_max: 5,
        optimal_value: 0,
        explanation: "Test"
      })

      result = Workshops.get_template_with_questions(template.id)
      assert result.id == template.id
      assert length(result.questions) == 1
      assert hd(result.questions).title == "Q1"
    end
  end
end
