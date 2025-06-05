
require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplateTest < ActiveSupport::TestCase
  def setup
    setup_test_user
    setup_test_project
  end

  def test_create_template
    template = SubtaskTemplate.new(
      name: 'Test Template',
      description: 'Test description',
      project: @project
    )
    
    assert template.save, "Template should be saved successfully"
    assert_equal 'Test Template', template.name
    assert_equal @project, template.project
  end

  def test_template_name_required
    template = SubtaskTemplate.new(description: 'Test description')
    assert_not template.save, "Template should not be saved without name"
    assert_includes template.errors[:name], "can't be blank"
  end

  def test_template_name_uniqueness_within_project
    # 最初のテンプレートを作成
    template1 = SubtaskTemplate.create!(
      name: 'Duplicate Name',
      project: @project
    )

    # 同じプロジェクト内で同じ名前のテンプレートを作成しようとする
    template2 = SubtaskTemplate.new(
      name: 'Duplicate Name',
      project: @project
    )

    assert_not template2.save, "Duplicate template name within same project should not be allowed"
    assert_includes template2.errors[:name], "has already been taken"
  end

  def test_template_name_uniqueness_across_projects
    project2 = Project.create!(
      name: 'Another Project',
      identifier: 'another-project'
    )

    # プロジェクト1でテンプレート作成
    template1 = SubtaskTemplate.create!(
      name: 'Same Name',
      project: @project
    )

    # プロジェクト2で同じ名前のテンプレート作成（これは許可される）
    template2 = SubtaskTemplate.new(
      name: 'Same Name',
      project: project2
    )

    assert template2.save, "Same template name across different projects should be allowed"
  end

  def test_global_template
    template = SubtaskTemplate.create!(
      name: 'Global Template',
      project: nil
    )

    assert template.project_id.nil?, "Global template should have no project"
    assert_equal 'Global Template (グローバル)', template.display_name
  end

  def test_project_template_display_name
    template = SubtaskTemplate.create!(
      name: 'Project Template',
      project: @project
    )

    assert_equal "Project Template (#{@project.name})", template.display_name
  end

  def test_template_with_subtask_items
    template = SubtaskTemplate.create!(
      name: 'Template with Items',
      project: @project
    )

    item1 = template.subtask_template_items.create!(
      title: 'First Task',
      description: 'First task description'
    )

    item2 = template.subtask_template_items.create!(
      title: 'Second Task',
      description: 'Second task description'
    )

    assert_equal 2, template.subtask_template_items.count
    assert_includes template.subtask_template_items, item1
    assert_includes template.subtask_template_items, item2
  end

  def test_destroy_template_destroys_items
    template = SubtaskTemplate.create!(
      name: 'Template to Delete',
      project: @project
    )

    item = template.subtask_template_items.create!(
      title: 'Item to be deleted',
      description: 'This item should be deleted with template'
    )

    item_id = item.id
    template.destroy

    assert_not SubtaskTemplateItem.exists?(item_id), "Subtask items should be deleted when template is destroyed"
  end

  def test_create_subtasks_for_issue
    # テンプレートの作成
    template = SubtaskTemplate.create!(
      name: 'Development Template',
      project: @project
    )

    # サブタスクアイテムの作成
    template.subtask_template_items.create!([
      {
        title: 'Design Task',
        description: 'Create design mockups',
        tracker_id: default_tracker.id,
        priority_id: default_priority.id
      },
      {
        title: 'Development Task',
        description: 'Implement the feature',
        assigned_to: @user,
        tracker_id: default_tracker.id
      }
    ])

    # 親チケットの作成
    parent_issue = Issue.create!(
      project: @project,
      tracker: default_tracker,
      subject: 'Parent Issue',
      description: 'Parent issue description',
      author: @user,
      priority: default_priority,
      status: IssueStatus.first
    )

    # サブタスクの作成
    assert_difference 'Issue.count', 2 do
      template.create_subtasks_for_issue(parent_issue)
    end

    # 作成されたサブタスクの検証
    subtasks = Issue.where(parent_issue_id: parent_issue.id)
    assert_equal 2, subtasks.count

    design_task = subtasks.find_by(subject: 'Design Task')
    assert_not_nil design_task
    assert_equal 'Create design mockups', design_task.description
    assert_equal parent_issue.project, design_task.project
    assert_equal parent_issue.id, design_task.parent_issue_id

    dev_task = subtasks.find_by(subject: 'Development Task')
    assert_not_nil dev_task
    assert_equal @user, dev_task.assigned_to
  end

  def test_scopes
    global_template = SubtaskTemplate.create!(name: 'Global', project: nil)
    project_template = SubtaskTemplate.create!(name: 'Project', project: @project)

    global_templates = SubtaskTemplate.global
    assert_includes global_templates, global_template
    assert_not_includes global_templates, project_template

    project_templates = SubtaskTemplate.for_project(@project)
    assert_includes project_templates, project_template
    assert_not_includes project_templates, global_template
  end
end
