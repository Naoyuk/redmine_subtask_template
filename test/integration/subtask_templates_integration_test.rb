require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplatesIntegrationTest < ActionDispatch::IntegrationTest
  
  def setup
    # テスト用ユーザーとプロジェクトをFactoryBotで作成
    @admin = create_admin_user
    @user = create_regular_user  
    @project = create_test_project
    
    # 基本的なRedmineデータを作成
    @tracker = create_tracker
    @priority = create_issue_priority
    @status = create_issue_status
  end

  def test_admin_can_access_template_management
    # 管理者がテンプレート管理にアクセスできることのテスト
    login_as_admin
    
    # 管理画面にアクセス
    get "/admin"
    assert_response :success
    
    # サブタスクテンプレートのリンクがあることを確認
    assert_select "a[href='/subtask_templates']", text: "📋 Subtask Templates"
    
    # テンプレート一覧にアクセス
    get "/subtask_templates"
    assert_response :success
    assert_select "h2", text: "Subtask Templates"
  end

  def test_regular_user_cannot_access_template_management
    # 一般ユーザーがテンプレート管理にアクセスできないことのテスト
    login_as_user
    
    get "/subtask_templates"
    assert_response 403
  end

  def test_complete_template_creation_workflow
    # テンプレート作成の完全なワークフローテスト
    login_as_admin
    
    # 新規作成画面にアクセス
    get "/subtask_templates/new"
    assert_response :success
    assert_select "h2", text: "New Subtask Template"
    
    # フォームが正しく表示されることを確認
    assert_select "form[action='/subtask_templates']" do
      assert_select "input[name='subtask_template[name]']"
      assert_select "textarea[name='subtask_template[description]']"
      assert_select "select[name='subtask_template[project_id]']"
    end
    
    # 初期サブタスクアイテムが表示されることを確認
    assert_select "div#subtask-items .nested-fields"
    assert_select "input[name*='[title]']"
    
    # FactoryBotのsequenceを使用して一意なテンプレート名を生成
    template_name = "Integration Test Template #{SecureRandom.hex(4)}"
    
    # テンプレートを作成
    post "/subtask_templates", params: {
      subtask_template: {
        name: template_name,
        description: "Created via integration test",
        project_id: @project.id,
        subtask_template_items_attributes: {
          "0" => {
            title: "Setup Task",
            description: "Initial setup",
            assigned_to_id: @admin.id,
            priority_id: @priority.id,
            tracker_id: @tracker.id
          },
          "1" => {
            title: "Review Task", 
            description: "Final review"
          }
        }
      }
    }
    
    # 作成後一覧にリダイレクトされることを確認
    assert_redirected_to "/subtask_templates"
    follow_redirect!
    
    # 成功メッセージが表示されることを確認
    assert_select "div.flash.notice", text: "Template was successfully created."
    
    # 作成されたテンプレートが一覧に表示されることを確認
    assert_select "td", text: template_name
    
    # テンプレートがデータベースに保存されていることを確認
    template = SubtaskTemplate.find_by(name: template_name)
    assert_not_nil template
    assert_equal @project.id, template.project_id
    assert_equal 2, template.subtask_template_items.count
  end

  def test_template_viewing_and_navigation
    # テンプレート表示とナビゲーションのテスト
    template = create_template_with_items
    login_as_admin
    
    # 一覧からテンプレート詳細にアクセス
    get "/subtask_templates"
    assert_response :success
    
    # テンプレートのリンクをクリック
    assert_select "a[href='/subtask_templates/#{template.id}']"
    get "/subtask_templates/#{template.id}"
    assert_response :success
    
    # 詳細画面の内容を確認
    assert_select "h2", text: template.name
    assert_select "strong", text: "Title:"
    assert_select "strong", text: "Description:"
    assert_select "strong", text: "Project:"
    
    # サブタスクアイテムが表示されることを確認
    assert_select "h3.subtask-items-title", text: /Subtask items \(\d+ tasks?\)/
    template.subtask_template_items.each do |item|
      assert_select "h4", text: /#{item.title}/
    end
    
    # 編集リンクがあることを確認
    assert_select "a[href='/subtask_templates/#{template.id}/edit']", text: "Edit"
    
    # 編集画面にアクセス
    get "/subtask_templates/#{template.id}/edit"
    assert_response :success
    assert_select "h2", text: "Edit Subtask Template"
    assert_select "input[value='#{template.name}']"
  end

  def test_template_editing_workflow
    # テンプレート編集ワークフローのテスト
    template = create_template_with_items
    login_as_admin
    
    # 編集画面にアクセス
    get "/subtask_templates/#{template.id}/edit"
    assert_response :success
    
    # 既存のデータが正しく表示されることを確認
    assert_select "input[value='#{template.name}']"
    assert_select "textarea", text: template.description
    
    # 既存のサブタスクアイテムが表示されることを確認
    template.subtask_template_items.each do |item|
      assert_select "input[value='#{item.title}']"
    end
    
    # SecureRandomを使用して一意な更新名を生成
    updated_name = "Updated Template Name #{SecureRandom.hex(4)}"
    
    # 更新を実行
    patch "/subtask_templates/#{template.id}", params: {
      subtask_template: {
        name: updated_name,
        description: "Updated description",
        subtask_template_items_attributes: {
          "0" => {
            id: template.subtask_template_items.first.id,
            title: "Updated First Task",
            description: "Updated description"
          },
          "1" => {
            id: template.subtask_template_items.last.id,
            title: template.subtask_template_items.last.title,
            _destroy: "1"  # 2番目のアイテムを削除
          }
        }
      }
    }
    
    # 更新後一覧にリダイレクトされることを確認
    assert_redirected_to "/subtask_templates"
    follow_redirect!
    
    # 成功メッセージが表示されることを確認
    assert_select "div.flash.notice", text: "Template was successfully updated."
    
    # データベースが正しく更新されていることを確認
    template.reload
    assert_equal updated_name, template.name
    assert_equal "Updated description", template.description
    assert_equal 1, template.subtask_template_items.count
    assert_equal "Updated First Task", template.subtask_template_items.first.title
  end

  def test_template_deletion_workflow
    # テンプレート削除ワークフローのテスト
    template = create_template_with_items
    template_id = template.id
    item_ids = template.subtask_template_items.pluck(:id)
    
    login_as_admin
    
    # 詳細画面にアクセス
    get "/subtask_templates/#{template.id}"
    assert_response :success
    
    # 削除リンクがあることを確認
    assert_select "a[href='/subtask_templates/#{template.id}']", text: "Delete"
    
    # 削除を実行
    delete "/subtask_templates/#{template.id}"
    
    # 削除後一覧にリダイレクトされることを確認
    assert_redirected_to "/subtask_templates"
    follow_redirect!
    
    # 成功メッセージが表示されることを確認
    assert_select "div.flash.notice", text: "Template was successfully deleted."
    
    # テンプレートがデータベースから削除されていることを確認
    assert_nil SubtaskTemplate.find_by(id: template_id)
    
    # 関連するサブタスクアイテムも削除されていることを確認
    item_ids.each do |item_id|
      assert_nil SubtaskTemplateItem.find_by(id: item_id)
    end
  end

  def test_validation_error_handling
    # バリデーションエラーのハンドリングテスト
    login_as_admin
    
    # 無効なデータでテンプレート作成を試行
    post "/subtask_templates", params: {
      subtask_template: {
        name: "",  # 空の名前
        description: "Test description",
        subtask_template_items_attributes: {
          "0" => {
            title: "",  # 空のタイトル
            description: "Test subtask"
          }
        }
      }
    }
    
    # エラー時は新規作成画面が再表示されることを確認
    assert_response :success
    assert_template "subtask_templates/new"
    
    # エラーメッセージが表示されることを確認（Redmineのerror_messages_forを使用）
    assert_select "div#errorExplanation", count: 1
  end

  def test_javascript_functionality_structure
    # JavaScript機能の構造をテスト（実際のJS実行はしない）
    login_as_admin
    
    get "/subtask_templates/new"
    assert_response :success
    
    # サブタスク追加ボタンがあることを確認
    assert_select "a#add-subtask-item", text: "Add Subtask"
    
    # JavaScriptファイルが読み込まれることを確認
    assert_select "script[src*='subtask_template.js']"
    
    # 削除ボタンの構造を確認
    assert_select ".nested-fields .remove_fields", text: "Delete"
  end

  def test_project_specific_vs_global_templates
    # プロジェクト固有テンプレートとグローバルテンプレートのテスト
    login_as_admin
    
    # SecureRandomを使用して一意な名前を生成
    global_template_name = "Global Template #{SecureRandom.hex(4)}"
    project_template_name = "Project Specific Template #{SecureRandom.hex(4)}"
    
    # グローバルテンプレートを作成
    post "/subtask_templates", params: {
      subtask_template: {
        name: global_template_name,
        description: "Available for all projects",
        project_id: "",  # 空でグローバル
        subtask_template_items_attributes: {
          "0" => { title: "Global Subtask" }
        }
      }
    }
    
    assert_redirected_to "/subtask_templates"
    follow_redirect!
    
    # プロジェクト固有テンプレートを作成
    post "/subtask_templates", params: {
      subtask_template: {
        name: project_template_name,
        description: "Only for specific project",
        project_id: @project.id,
        subtask_template_items_attributes: {
          "0" => { title: "Project Subtask" }
        }
      }
    }
    
    assert_redirected_to "/subtask_templates"
    follow_redirect!
    
    # 両方のテンプレートが一覧に表示されることを確認
    get "/subtask_templates"
    assert_select "td", text: global_template_name
    assert_select "td", text: project_template_name
    assert_select "td", text: "Global"
    assert_select "td", text: @project.name
    
    # データベースで正しく保存されていることを確認
    global_template = SubtaskTemplate.find_by(name: global_template_name)
    assert_nil global_template.project_id
    
    project_template = SubtaskTemplate.find_by(name: project_template_name)
    assert_equal @project.id, project_template.project_id
  end

  def test_empty_template_list_display
    # 空のテンプレートリスト表示のテスト
    login_as_admin
    
    # すべてのテンプレートを削除
    SubtaskTemplate.delete_all
    
    get "/subtask_templates"
    assert_response :success
    
    # 「データなし」メッセージが表示されることを確認
    assert_select "p.nodata", text: "No templates found."
    
    # 新規作成リンクは表示されることを確認
    assert_select "a[href='/subtask_templates/new']", text: "New Template"
  end

  def test_form_cancel_navigation
    # フォームのキャンセルナビゲーションテスト
    login_as_admin
    
    # 新規作成画面のキャンセルリンク
    get "/subtask_templates/new"
    assert_select "a[href='/subtask_templates']", text: "Cancel"
    
    # 編集画面のキャンセルリンク
    template = create_template_with_items
    get "/subtask_templates/#{template.id}/edit"
    assert_select "a[href='/subtask_templates']", text: "Cancel"
    assert_select "a[href='/subtask_templates/#{template.id}']", text: "Show"
  end

  private

  def login_as_admin
    post "/login", params: {
      username: @admin.login,
      password: "password"
    }
    assert_redirected_to "/my/page"
  end

  def login_as_user
    post "/login", params: {
      username: @user.login,
      password: "password"
    }
    assert_redirected_to "/my/page"
  end

  # FactoryBotを使用してテストデータを作成、フォールバック付き
  def create_admin_user
    begin
      # FactoryBotのsequence機能を活用
      FactoryBot.create(:user, admin: true)
    rescue NameError, LoadError, NoMethodError
      # FactoryBot利用できない場合のフォールバック
      User.create!(
        login: "admin#{SecureRandom.hex(4)}",
        firstname: "Admin",
        lastname: "User",
        mail: "admin#{SecureRandom.hex(4)}@example.com",
        admin: true,
        status: User::STATUS_ACTIVE,
        password: "password",
        password_confirmation: "password"
      )
    end
  end

  def create_regular_user
    begin
      # FactoryBotのsequence機能を活用
      FactoryBot.create(:user, admin: false)
    rescue NameError, LoadError, NoMethodError
      # FactoryBot利用できない場合のフォールバック
      User.create!(
        login: "user#{SecureRandom.hex(4)}",
        firstname: "Regular",
        lastname: "User",
        mail: "user#{SecureRandom.hex(4)}@example.com",
        admin: false,
        status: User::STATUS_ACTIVE,
        password: "password",
        password_confirmation: "password"
      )
    end
  end

  def create_test_project
    begin
      # FactoryBotのsequence機能を活用
      FactoryBot.create(:project)
    rescue NameError, LoadError, NoMethodError
      # FactoryBot利用できない場合のフォールバック
      Project.create!(
        name: "Test Project #{SecureRandom.hex(4)}",
        identifier: "test-project-#{SecureRandom.hex(4)}",
        status: Project::STATUS_ACTIVE
      )
    end
  end

  def create_issue_priority
    begin
      # FactoryBotのsequence機能を活用
      FactoryBot.create(:issue_priority)
    rescue NameError, LoadError, NoMethodError
      # FactoryBot利用できない場合のフォールバック
      IssuePriority.create!(
        name: "Test Priority #{SecureRandom.hex(4)}",
        position: 1
      )
    end
  end

  def create_issue_status
    begin
      # FactoryBotのsequence機能を活用  
      FactoryBot.create(:issue_status)
    rescue NameError, LoadError, NoMethodError
      # FactoryBot利用できない場合のフォールバック
      IssueStatus.create!(
        name: "New #{SecureRandom.hex(4)}",
        position: 1
      )
    end
  end

  def create_tracker
    begin
      # FactoryBotのsequence機能を活用
      FactoryBot.create(:tracker)
    rescue NameError, LoadError, NoMethodError
      # FactoryBot利用できない場合のフォールバック
      status = create_issue_status
      Tracker.create!(
        name: "Test Tracker #{SecureRandom.hex(4)}",
        default_status: status,
        core_fields: Tracker::CORE_FIELDS
      )
    end
  end

  def create_template_with_items
    begin
      # FactoryBotのsequence機能とtraitを活用
      FactoryBot.create(:subtask_template, :with_subtask_items, project: @project)
    rescue NameError, LoadError, NoMethodError
      # FactoryBot利用できない場合のフォールバック
      template = SubtaskTemplate.create!(
        name: "Integration Test Template #{SecureRandom.hex(4)}",
        description: "Test template description",
        project_id: @project.id
      )
      
      SubtaskTemplateItem.create!(
        subtask_template: template,
        title: "First Integration Task",
        description: "First task description",
        assigned_to_id: @admin.id,
        priority_id: @priority.id,
        tracker_id: @tracker.id
      )
      
      SubtaskTemplateItem.create!(
        subtask_template: template,
        title: "Second Integration Task",
        description: "Second task description"
      )
      
      template
    end
  end
end
