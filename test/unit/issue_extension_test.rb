require File.expand_path('../../test_helper', __FILE__)

class IssueExtensionTest < ActiveSupport::TestCase

  def test_issue_should_have_subtask_template_id_attribute
    # IssueにsubtaskTemplate_idアクセサーが追加されることのテスト
    issue = create(:issue)

    # virtual attributeとして使用可能であることを確認
    assert_respond_to issue, :subtask_template_id
    assert_respond_to issue, :subtask_template_id=

    # 値の設定と取得
    issue.subtask_template_id = 123
    assert_equal 123, issue.subtask_template_id
  end

  def test_issue_should_apply_subtask_template_after_save_when_template_id_present
    # Issue保存後にテンプレートが適用されることのテスト
    project = create(:project)
    template = create(:subtask_template, project: project)

    # テンプレートアイテムを作成
    create(:subtask_template_item,
      subtask_template: template,
      title: "Automated Subtask 1"
    )
    create(:subtask_template_item,
      subtask_template: template,
      title: "Automated Subtask 2"
    )

    # Issue作成時にテンプレートIDを設定
    issue = build(:issue, project: project)
    issue.subtask_template_id = template.id.to_s

    # サブタスクが存在しないことを確認
    assert_equal 0, issue.children.count

    # Issue保存
    assert issue.save

    # サブタスクが自動生成されることを確認
    issue.reload
    assert_equal 2, issue.children.count

    subtasks = issue.children.order(:created_at)
    assert_equal "Automated Subtask 1", subtasks[0].subject
    assert_equal "Automated Subtask 2", subtasks[1].subject

    # サブタスクの親子関係を確認
    subtasks.each do |subtask|
      assert_equal issue, subtask.parent
      assert_equal project, subtask.project
    end
  end

  def test_issue_should_not_apply_template_when_template_id_is_blank
    # テンプレートIDが空の場合は何もしないことのテスト
    project = create(:project)
    template = create(:subtask_template, project: project)

    create(:subtask_template_item,
      subtask_template: template,
      title: "Should Not Create"
    )

    # テンプレートIDを空に設定
    issue = build(:issue, project: project)
    issue.subtask_template_id = ""

    assert issue.save

    # サブタスクが作成されないことを確認
    issue.reload
    assert_equal 0, issue.children.count
  end

  def test_issue_should_not_apply_template_when_template_id_is_nil
    # テンプレートIDがnilの場合は何もしないことのテスト
    project = create(:project)
    template = create(:subtask_template, project: project)

    create(:subtask_template_item,
      subtask_template: template,
      title: "Should Not Create"
    )

    # テンプレートIDをnilに設定
    issue = build(:issue, project: project)
    issue.subtask_template_id = nil

    assert issue.save

    # サブタスクが作成されないことを確認
    issue.reload
    assert_equal 0, issue.children.count
  end

  def test_issue_should_handle_invalid_template_id_gracefully
    # 無効なテンプレートIDでもエラーにならないことのテスト
    project = create(:project)

    # 存在しないテンプレートIDを設定
    issue = build(:issue, project: project)
    issue.subtask_template_id = "0"

    # Issue保存が成功することを確認（エラーにならない）
    assert issue.save

    # サブタスクが作成されないことを確認
    issue.reload
    assert_equal 0, issue.children.count
  end

  def test_issue_should_only_apply_template_on_create_not_update
    # 新規作成時のみテンプレートが適用され、更新時は適用されないことのテスト
    project = create(:project)
    template = create(:subtask_template, project: project)

    create(:subtask_template_item,
      subtask_template: template,
      title: "Create Only Subtask"
    )

    # 最初にテンプレートなしでIssueを作成
    issue = create(:issue, project: project)
    assert_equal 0, issue.children.count

    # 更新時にテンプレートIDを設定
    issue.subtask_template_id = template.id.to_s
    issue.subject = "Updated Subject"
    assert issue.save

    # サブタスクが作成されないことを確認（更新時は適用されない）
    issue.reload
    assert_equal 0, issue.children.count
  end

  def test_issue_should_not_apply_template_for_child_issues
    # 子Issue（サブタスク）にはテンプレートが適用されないことのテスト
    project = create(:project)
    parent_issue = create(:issue, project: project)
    template = create(:subtask_template, project: project)

    create(:subtask_template_item,
      subtask_template: template,
      title: "Should Not Create for Child"
    )

    # 子Issueを作成
    child_issue = build(:issue, project: project, parent: parent_issue)
    child_issue.subtask_template_id = template.id.to_s

    assert child_issue.save

    # 孫Issueが作成されないことを確認
    child_issue.reload
    assert_equal 0, child_issue.children.count
  end

  def test_issue_should_apply_project_specific_template_correctly
    # プロジェクト固有テンプレートの適用テスト
    project = create(:project)
    other_project = create(:project)

    template = create(:subtask_template, name: "Project Template", project: project)
    other_template = create(:subtask_template, name: "Other Project Template", project: other_project)

    create(:subtask_template_item,
      subtask_template: template,
      title: "Project Specific Task"
    )

    # プロジェクトのテンプレートを適用
    issue = build(:issue, project: project)
    issue.subtask_template_id = template.id.to_s

    assert issue.save

    issue.reload
    assert_equal 1, issue.children.count
    assert_equal "Project Specific Task", issue.children.first.subject
  end

  def test_issue_should_apply_global_template_correctly
    # グローバルテンプレートの適用テスト
    project = create(:project)
    global_template = create(:subtask_template, name: "Global Template", project: nil)

    create(:subtask_template_item,
      subtask_template: global_template,
      title: "Global Task"
    )

    # グローバルテンプレートを適用
    issue = build(:issue, project: project)
    issue.subtask_template_id = global_template.id.to_s

    assert issue.save

    issue.reload
    assert_equal 1, issue.children.count
    assert_equal "Global Task", issue.children.first.subject
  end

  def test_issue_should_maintain_template_id_during_validation_errors
    # バリデーションエラー時もテンプレートIDが保持されることのテスト
    project = create(:project)
    template = create(:subtask_template, project: project)

    # 無効なIssueを作成（subjectが空）
    issue = Issue.new(project: project, subject: "")
    issue.subtask_template_id = template.id.to_s

    # バリデーションエラーが発生することを確認
    assert_not issue.save

    # テンプレートIDが保持されていることを確認
    assert_equal template.id.to_s, issue.subtask_template_id
  end

  def test_issue_should_handle_template_application_errors_gracefully
    # テンプレート適用時のエラーを適切に処理することのテスト
    project = create(:project)
    template = create(:subtask_template, project: project)

    # 無効なテンプレートアイテム（titleが空）を作成
    create(:subtask_template_item,
      subtask_template: template,
      title: "" # 無効なデータ
    )

    issue = build(:issue, project: project)
    issue.subtask_template_id = template.id.to_s

    # Issue保存は成功することを確認（テンプレート適用エラーでIssue保存が失敗しない）
    assert issue.save

    # 無効なサブタスクは作成されないことを確認
    issue.reload
    assert_equal 0, issue.children.count
  end

  def test_issue_extension_should_not_interfere_with_normal_issue_operations
    # Issue拡張が通常のIssue操作に影響しないことのテスト
    project = create(:project)

    # 通常のIssue作成
    issue = create(:issue, project: project, subject: "Normal Issue")

    # 基本的な操作が正常に動作することを確認
    assert_equal "Normal Issue", issue.subject
    assert_equal project, issue.project

    # 更新操作
    issue.subject = "Updated Normal Issue"
    assert issue.save
    assert_equal "Updated Normal Issue", issue.subject

    # 削除操作
    issue_id = issue.id
    issue.destroy
    assert_nil Issue.find_by(id: issue_id)
  end
end
