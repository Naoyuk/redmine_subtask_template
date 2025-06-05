require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplateIntegrationTest < ActionDispatch::IntegrationTest
  fixtures :projects, :users, :trackers, :issue_statuses, :issues,
           :enumerations, :roles, :members, :member_roles

  def setup
    @admin = User.find_by_login('admin') || User.first
    @project = Project.find(1) || Project.first
  end

  def test_complete_template_workflow
    # 管理者としてログイン
    log_user('admin', 'admin')

    # テンプレート一覧ページにアクセス
    get '/subtask_templates'
    assert_response :success
    assert_select 'h2', text: 'サブタスクテンプレート'

    # 新規テンプレート作成ページにアクセス
    get '/subtask_templates/new'
    assert_response :success
    assert_select 'form'

    # テンプレートを作成
    post '/subtask_templates', params: {
      subtask_template: {
        name: 'Integration Test Template',
        description: 'Created via integration test',
        project_id: @project.id,
        subtask_template_items_attributes: {
          '0' => {
            title: 'Design Task',
            description: 'Create UI mockups'
          },
          '1' => {
            title: 'Development Task',
            description: 'Implement the feature'
          }
        }
      }
    }
    
    assert_redirected_to '/subtask_templates'
    follow_redirect!
    assert_select '.flash.notice', text: 'テンプレートが作成されました。'

    # 作成されたテンプレートが一覧に表示されることを確認
    assert_select 'td', text: 'Integration Test Template'

    # テンプレートの詳細ページにアクセス
    template = SubtaskTemplate.find_by(name: 'Integration Test Template')
    get "/subtask_templates/#{template.id}"
    assert_response :success

    # テンプレートの編集ページにアクセス
    get "/subtask_templates/#{template.id}/edit"
    assert_response :success

    # テンプレートを更新
    put "/subtask_templates/#{template.id}", params: {
      subtask_template: {
        name: 'Updated Integration Test Template',
        description: 'Updated via integration test'
      }
    }
    
    assert_redirected_to '/subtask_templates'
    follow_redirect!
    assert_select '.flash.notice', text: 'テンプレートが更新されました。'

    # 更新されたテンプレート名が表示されることを確認
    assert_select 'td', text: 'Updated Integration Test Template'

    # テンプレートを削除
    delete "/subtask_templates/#{template.id}"
    assert_redirected_to '/subtask_templates'
    follow_redirect!
    assert_select '.flash.notice', text: 'テンプレートが削除されました。'

    # テンプレートが一覧から削除されていることを確認
    assert_select 'td', text: 'Updated Integration Test Template', count: 0
  end

  def test_template_with_issue_creation
    # 管理者としてログイン
    log_user('admin', 'admin')

    # テンプレートを作成
    template = SubtaskTemplate.create!(
      name: 'Issue Creation Template',
      project: @project
    )

    template.subtask_template_items.create!([
      {
        title: 'Analysis Task',
        description: 'Analyze requirements',
        tracker_id: Tracker.first.id
      },
      {
        title: 'Implementation Task',
        description: 'Implement solution',
        assigned_to_id: @admin.id
      }
    ])

    # 親チケットを作成
    parent_issue = Issue.create!(
      project: @project,
      tracker: Tracker.first,
      subject: 'Parent Issue for Template Test',
      description: 'This issue will have subtasks from template',
      author: @admin,
      priority: IssuePriority.default || IssuePriority.first,
      status: IssueStatus.first
    )

    # テンプレートからサブタスクを作成
    initial_issue_count = Issue.count
    template.create_subtasks_for_issue(parent_issue)

    # サブタスクが作成されたことを確認
    assert_equal initial_issue_count + 2, Issue.count

    # 作成されたサブタスクの内容を確認
    subtasks = Issue.where(parent_issue_id: parent_issue.id)
    assert_equal 2, subtasks.count

    analysis_task = subtasks.find_by(subject: 'Analysis Task')
    assert_not_nil analysis_task
    assert_equal 'Analyze requirements', analysis_task.description
    assert_equal @project, analysis_task.project
    assert_equal parent_issue.id, analysis_task.parent_issue_id

    implementation_task = subtasks.find_by(subject: 'Implementation Task')
    assert_not_nil implementation_task
    assert_equal @admin, implementation_task.assigned_to
  end

  def test_global_vs_project_templates
    # 管理者としてログイン
    log_user('admin', 'admin')

    # グローバルテンプレートを作成
    global_template = SubtaskTemplate.create!(
      name: 'Global Template',
      project: nil
    )

    # プロジェクト固有テンプレートを作成
    project_template = SubtaskTemplate.create!(
      name: 'Project Template',
      project: @project
    )

    # テンプレート一覧ページで両方が表示されることを確認
    get '/subtask_templates'
    assert_response :success
    
    assert_select 'td', text: 'Global Template'
    assert_select 'td', text: 'Project Template'
    assert_select 'td', text: 'グローバル'
    assert_select 'td', text: @project.name
  end

  def test_permission_controls
    # 一般ユーザーを作成
    user = User.create!(
      login: 'normaluser',
      firstname: 'Normal',
      lastname: 'User',
      mail: 'normal@example.com',
      language: 'en'
    )

    # 一般ユーザーとしてログイン
    log_user('normaluser', 'password')

    # テンプレート一覧ページにアクセス（アクセス拒否されるべき）
    get '/subtask_templates'
    assert_response :forbidden
  end

  def test_nested_attributes_handling
    # 管理者としてログイン
    log_user('admin', 'admin')

    # ネストした属性でテンプレートを作成
    post '/subtask_templates', params: {
      subtask_template: {
        name: 'Nested Attributes Template',
        description: 'Testing nested attributes',
        project_id: @project.id,
        subtask_template_items_attributes: {
          '0' => {
            title: 'First Subtask',
            description: 'First subtask description',
            assigned_to_id: @admin.id,
            tracker_id: Tracker.first.id,
            priority_id: IssuePriority.first.id
          },
          '1' => {
            title: 'Second Subtask',
            description: 'Second subtask description'
          }
        }
      }
    }

    assert_redirected_to '/subtask_templates'
    
    # テンプレートとサブタスクアイテムが正しく作成されたことを確認
    template = SubtaskTemplate.find_by(name: 'Nested Attributes Template')
    assert_not_nil template
    assert_equal 2, template.subtask_template_items.count

    first_item = template.subtask_template_items.find_by(title: 'First Subtask')
    assert_not_nil first_item
    assert_equal 'First subtask description', first_item.description
    assert_equal @admin, first_item.assigned_to
    assert_equal Tracker.first, first_item.tracker
    assert_equal IssuePriority.first, first_item.priority

    second_item = template.subtask_template_items.find_by(title: 'Second Subtask')
    assert_not_nil second_item
    assert_equal 'Second subtask description', second_item.description
  end

  private

  def log_user(login, password)
    # セッションでユーザーを設定（簡易版）
    user = User.find_by_login(login)
    if user
      # 直接セッションに設定（統合テスト用）
      post '/login', params: {
        username: login,
        password: password
      }
    end
  rescue
    # ログイン処理でエラーが発生した場合は、User.currentで直接設定
    user = User.find_by_login(login)
    User.current = user if user
  end
end
