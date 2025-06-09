require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplateTest < ActiveSupport::TestCase
  
  def test_should_create_template
    # Factoryが有効であることのテスト
    template = build(:subtask_template)

    assert template.save
    assert_nil template.project_id
  end
  
  def test_should_require_name
    # nameが必須であることのテスト
    template = build(:subtask_template, name: nil)

    assert_not template.save
    assert template.errors[:name].present?
  end
  
  def test_should_validate_name_length
    # nameの長さ制限のテスト
    template = build(:subtask_template, name: "a" * 256)

    assert_not template.save
    assert template.errors[:name].present?
  end
  
  def test_should_validate_name_uniqueness_globally
    # グローバルテンプレートでのname一意性テスト
    create(:subtask_template, name: "Unique Template")
    template = build(:subtask_template, name: "Unique Template")

    assert_not template.save
    assert template.errors[:name].present?
  end
  
  def test_should_validate_name_uniqueness_within_project
    # プロジェクト内でのname一意性テスト
    project = create(:project)
    create(:subtask_template, name: 'Project Template', project: project)
    template = build(:subtask_template, name: 'Project Template', project: project)

    assert_not template.save
    assert template.errors[:name].present?
  end
  
  def test_should_allow_same_name_across_different_projects
    # 異なるプロジェクト間では同じ名前を許可
    project1 = create(:project)
    project2 = create(:project)

    create(:subtask_template, name: "Same Name", project: project1)
    template2 = build(:subtask_template, name: "Same Name", project: project2)

    assert template2.save
  end
  
  def test_should_allow_same_name_for_global_and_project_templates
    # グローバルテンプレートとプロジェクトテンプレートで同じ名前を許可
    project = create(:project)
    global_template = create(:subtask_template, name: "Template Name")
    project_template = build(:subtask_template, name: "Template Name", project: project)

    assert project_template.save
  end
  
  def test_display_name_for_global_template
    # グローバルテンプレートのdisplay_nameテスト
    template = create(:subtask_template, name: "Global Template")

    assert_equal "Global Template (Global)", template.display_name
  end
  
  def test_display_name_for_project_template
    # プロジェクトテンプレートのdisplay_nameテスト
    project = create(:project, name: "Test Project")
    template = create(:subtask_template, name: "Project Template", project: project)

    assert_equal "Project Template (Test Project)", template.display_name
  end
  
  def test_global_scope
    # globalスコープのテスト
    project = create(:project)
    project_template = create(:subtask_template, project: project)
    global_template = create(:subtask_template)
    global_templates = SubtaskTemplate.global

    assert_includes global_templates, global_template
    assert_not_includes global_templates, project_template
  end
  
  def test_for_project_scope
    # for_projectスコープのテスト
    project = create(:project)
    global_template = create(:subtask_template)
    project_template = create(:subtask_template, project: project)
    project_templates = SubtaskTemplate.for_project(project)

    assert_includes project_templates, project_template
    assert_not_includes project_templates, global_template
    # THINK: for_projectにはGlobal Templateは含むべきかどうか？
  end
  
  def test_association_with_subtask_template_items
    # SubtaskTemplateItemとの関連テスト
    template = create(:subtask_template)
    item1 = template.subtask_template_items.create!(title: "Subtask 1")
    item2 = template.subtask_template_items.create!(title: "Subtask 2")

    assert_equal 2, template.subtask_template_items.count
    assert_includes template.subtask_template_items, item1
    assert_includes template.subtask_template_items, item2
  end
  
  def test_should_destroy_dependent_items
    # テンプレート削除時に関連するアイテムも削除されることのテスト
    template = create(:subtask_template)
    item = template.subtask_template_items.create!(title: "Subtask Item")

    item_id = item.id
    template.destroy

    assert_nil SubtaskTemplateItem.find_by(id: item_id)
  end
  
  def test_accepts_nested_attributes_for_items
    # ネストした属性での作成テスト
    template_params = {
      name: "Template with Nested Items",
      subtask_template_items_attributes: [
        { title: "Nested Subtask 1", description: "Description 1" },
        { title: "Nested Subtask 2", description: "Description 2" }
      ]
    }

    template = SubtaskTemplate.create!(template_params)

    assert_equal 2, template.subtask_template_items.count
    assert_equal "Nested Subtask 1", template.subtask_template_items.first.title
    assert_equal "Nested Subtask 2", template.subtask_template_items.last.title
  end

  def test_available_for_project_should_include_global_and_project_templates
    # プロジェクトで利用可能なテンプレート取得のテスト
    project = create(:project)
    other_project = create(:project)

    global_template = create(:subtask_template, name: "Global Template", project: nil)
    project_template = create(:subtask_template, name: "Project Template", project: project)
    other_project_template = create(:subtask_template, name: "Other Project Template", project: other_project)

    available_templates = SubtaskTemplate.available_for_project(project)

    assert_includes available_templates, global_template
    assert_includes available_templates, project_template
    assert_not_includes available_templates, other_project_template
    assert_equal 2, available_templates.count
  end

  def test_available_for_project_should_return_only_global_when_project_is_nil
    # プロジェクトがnilの場合はグローバルテンプレートのみ返すテスト
    project = create(:project)

    global_template = create(:subtask_template, name: "Global Template", project: nil)
    project_template = create(:subtask_template, name: "Project Template", project: project)

    available_templates = SubtaskTemplate.available_for_project(nil)

    assert_includes available_templates, global_template
    assert_not_includes available_templates, project_template
    assert_equal 1, available_templates.count
  end

  def test_available_for_project_should_return_ordered_by_name
    # available_for_projectが名前順で返されることのテスト
    project = create(:project)

    template_c = create(:subtask_template, name: "C Template", project: project)
    template_a = create(:subtask_template, name: "A Template", project: nil)
    template_b = create(:subtask_template, name: "B Template", project: project)

    available_templates = SubtaskTemplate.available_for_project(project)

    assert_equal 3, available_templates.count
    assert_equal "A Template", available_templates[0].name
    assert_equal "B Template", available_templates[1].name
    assert_equal "C Template", available_templates[2].name
  end

  def test_options_for_select_should_return_array_for_dropdown
    # select_optionsでドロップダウン用の配列を返すテスト
    project = create(:project)

    global_template = create(:subtask_template, name: "Global Template", project: nil)
    project_template = create(:subtask_template, name: "Project Template", project: project)

    options = SubtaskTemplate.options_for_select(project)

    expected_options = [
      ["", ""], # 空の選択肢
      ["Global Template", global_template.id],
      ["Project Template", project_template.id]
    ]

    assert_equal expected_options, options
  end

  def test_options_for_select_should_include_empty_option_first
    # select_optionsで空の選択肢が最初に含まれることのテスト
    project = create(:project)
    create(:subtask_template, name: "Test Template", project: project)

    options = SubtaskTemplate.options_for_select(project)
    
    assert_equal ["", ""], options.first
    assert options.length > 1
  end

  def test_create_subtasks_for_issue_should_generate_child_issues
    # Issueに対してサブタスクを生成するテスト
    project = create(:project)
    parent_issue = create(:issue, project: project)
    template = create(:subtask_template, project: project)

    # テンプレートアイテムを作成
    user = create(:user)
    priority = create(:issue_priority)
    tracker = create(:tracker)

    create(:subtask_template_item, 
      subtask_template: template,
      title: "Subtask 1",
      description: "Description for subtask 1",
      assigned_to: user,
      priority: priority,
      tracker: tracker
    )

    create(:subtask_template_item,
      subtask_template: template, 
      title: "Subtask 2",
      description: "Description for subtask 2"
    )

    # サブタスク生成を実行
    created_issues = template.create_subtasks_for_issue(parent_issue)

    # 結果の検証
    assert_equal 2, created_issues.count

    first_subtask = created_issues.first
    assert_equal "Subtask 1", first_subtask.subject
    assert_equal "Description for subtask 1", first_subtask.description
    assert_equal parent_issue, first_subtask.parent
    assert_equal project, first_subtask.project
    assert_equal user, first_subtask.assigned_to
    assert_equal priority, first_subtask.priority
    assert_equal tracker, first_subtask.tracker

    second_subtask = created_issues.second
    assert_equal "Subtask 2", second_subtask.subject
    assert_equal "Description for subtask 2", second_subtask.description
    assert_equal parent_issue, second_subtask.parent
    assert_equal project, second_subtask.project
  end

  def test_create_subtasks_for_issue_should_use_default_values_when_template_item_values_are_nil
    # テンプレートアイテムの値がnilの場合はデフォルト値を使用するテスト
    project = create(:project)
    parent_issue = create(:issue, project: project)
    template = create(:subtask_template, project: project)

    create(:subtask_template_item,
      subtask_template: template,
      title: "Minimal Subtask",
      description: nil,
      assigned_to: nil,
      priority: nil,
      tracker: nil
    )

    created_issues = template.create_subtasks_for_issue(parent_issue)

    assert_equal 1, created_issues.count
    subtask = created_issues.first

    assert_equal "Minimal Subtask", subtask.subject
    assert_equal "", subtask.description
    assert_nil subtask.assigned_to
    assert_equal parent_issue.priority, subtask.priority
    assert_equal parent_issue.tracker, subtask.tracker
  end

  def test_create_subtasks_for_issue_should_return_empty_array_when_no_items
    # テンプレートアイテムがない場合は空配列を返すテスト
    project = create(:project)
    parent_issue = create(:issue, project: project)
    template = create(:subtask_template, project: project)

    # テンプレートアイテムは作成しない
    created_issues = template.create_subtasks_for_issue(parent_issue)

    assert_equal [], created_issues
  end

  def test_create_subtasks_for_issue_should_handle_validation_errors_gracefully
    # バリデーションエラーが発生した場合の適切な処理テスト
    project = create(:project)
    parent_issue = create(:issue, project: project)
    template = create(:subtask_template, project: project)

    # 無効なデータでテンプレートアイテムを作成
    create(:subtask_template_item,
      subtask_template: template,
      title: "", # 空のタイトル（バリデーションエラーになる）
      description: "Valid description"
    )

    # エラーが発生しても例外は投げずに、作成できなかったIssueは結果に含まれない
    created_issues = template.create_subtasks_for_issue(parent_issue)

    assert_equal [], created_issues
  end

  def test_create_subtasks_for_issue_should_preserve_issue_creation_order
    # サブタスク作成順序が保持されることのテスト
    project = create(:project)
    parent_issue = create(:issue, project: project)
    template = create(:subtask_template, project: project)

    # 順序を明確にするため、作成時刻を少しずらす
    item1 = create(:subtask_template_item,
      subtask_template: template,
      title: "First Task",
      created_at: 3.minutes.ago
    )

    item2 = create(:subtask_template_item,
      subtask_template: template,
      title: "Second Task", 
      created_at: 2.minutes.ago
    )

    item3 = create(:subtask_template_item,
      subtask_template: template,
      title: "Third Task",
      created_at: 1.minute.ago
    )

    created_issues = template.create_subtasks_for_issue(parent_issue)

    assert_equal 3, created_issues.count
    assert_equal "First Task", created_issues[0].subject
    assert_equal "Second Task", created_issues[1].subject
    assert_equal "Third Task", created_issues[2].subject
  end

  def test_create_subtasks_for_issue_should_set_author_from_parent_issue
    # サブタスクの作成者が親Issueの作成者に設定されることのテスト
    project = create(:project)
    author = create(:user)
    parent_issue = create(:issue, project: project, author: author)
    template = create(:subtask_template, project: project)

    create(:subtask_template_item,
      subtask_template: template,
      title: "Author Test Task"
    )

    created_issues = template.create_subtasks_for_issue(parent_issue)

    assert_equal 1, created_issues.count
    assert_equal author, created_issues.first.author
  end

  def test_create_subtasks_for_issue_should_set_status_from_parent_issue
    # サブタスクのステータスが親Issueのステータスまたはデフォルトに設定されることのテスト
    project = create(:project)
    status = create(:issue_status)
    parent_issue = create(:issue, project: project, status: status)
    template = create(:subtask_template, project: project)

    create(:subtask_template_item,
      subtask_template: template,
      title: "Status Test Task"
    )

    created_issues = template.create_subtasks_for_issue(parent_issue)

    assert_equal 1, created_issues.count
    # Redmineの仕様に従い、新しいIssueのデフォルトステータスが設定される
    assert_not_nil created_issues.first.status
  end

  def test_apply_template_to_issue_should_be_alias_for_create_subtasks_for_issue
    # apply_template_to_issueメソッドがcreate_subtasks_for_issueのエイリアスとして動作することのテスト
    project = create(:project)
    parent_issue = create(:issue, project: project)
    template = create(:subtask_template, project: project)

    create(:subtask_template_item,
      subtask_template: template,
      title: "Alias Test Task"
    )

    # apply_template_to_issueメソッドを使用してサブタスク生成を実行
    created_issues = template.apply_template_to_issue(parent_issue)

    assert_equal 1, created_issues.count
    assert_equal "Alias Test Task", created_issues.first.subject

    create(:subtask_template_item,
      title: "Subtask 1",
      description: "Description for subtask 1",
      assigned_to: user,
      priority: priority,
      tracker: tracker
    )

    create(:subtask_template_item,
      subtask_template: template, 
      title: "Subtask 2",
      description: "Description for subtask 2"
    )

    # create_subtasks_for_issueを使用してサブタスク生成を実行
    created_issues = template.create_subtasks_for_issue(parent_issue)

    # 結果の検証
    assert_equal 2, created_issues.count

    first_subtask = created_issues.first
    assert_equal "Subtask 1", first_subtask.subject
    assert_equal "Description for subtask 1", first_subtask.description
    assert_equal parent_issue, first_subtask.parent
    assert_equal project, first_subtask.project
    assert_equal user, first_subtask.assigned_to
    assert_equal priority, first_subtask.priority
    assert_equal tracker, first_subtask.tracker

    second_subtask = created_issues.second
    assert_equal "Subtask 2", second_subtask.subject
    assert_equal "Description for subtask 2", second_subtask.description
    assert_equal parent_issue, second_subtask.parent
    assert_equal project, second_subtask.project
  end
end
