require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplatesControllerTest < ActionController::TestCase
  def setup
    # 管理者ユーザーを作成
    @admin = User.find_by(admin: true) || create(:user, admin: true)
    User.current = @admin
    @request.session[:user_id] = @admin.id

    # 一般ユーザーを作成
    @user = create(:user)

    # テスト用プロジェクトを作成
    @project = create(:project)

    # テストデータの準備
    @template = create_template_with_items
  end

  def test_index_should_display_templates
    # 一覧表示のテスト
    get :index

    assert_response :success
    assert_template 'index'
    assert_select 'h2', text: 'Subtask Templates'
  end

  def test_index_should_show_template_list
    # テンプレートが一覧に表示されることのテスト
    template = create(:subtask_template)

    get :index

    assert_response :success
    assert_select 'td', text: template.name
  end

  def test_index_should_show_no_data_message_when_empty
    # テンプレートがない場合のメッセージ表示テスト
    SubtaskTemplate.delete_all

    get :index

    assert_response :success
    assert_select 'p.nodata', text: 'No templates found.'
  end

  def test_new_should_display_form
    # 新規作成フォーム表示のテスト
    get :new

    assert_response :success
    assert_template 'new'
    assert_select 'h2', text: 'New Subtask Template'
  end

  def test_new_should_build_initial_subtask_item
    # 新規作成時に初期サブタスクアイテムが作成されることのテスト
    get :new

    assert_response :success
    assert assigns(:template).subtask_template_items.any?
    assert_select 'div#subtask-items .nested-fields', minimum: 1
  end

  def test_create_should_save_valid_template
    # 有効なテンプレートの作成テスト
    assert_difference 'SubtaskTemplate.count', 1 do
      post :create, params: {
        subtask_template: {
          name: "New Test Template #{Time.current.to_i}",
          description: 'Test description',
          project_id: @project.id
        }
      }
    end

    assert_redirected_to subtask_templates_path
    assert_equal 'Template was successfully created.', flash[:notice]

    template = SubtaskTemplate.last
    assert_equal 'Test description', template.description
    assert_equal @project.id, template.project_id
  end

  def test_create_should_save_global_template
    # グローバルテンプレートの作成テスト
    assert_difference 'SubtaskTemplate.count', 1 do
      post :create, params: {
        subtask_template: {
          name: "Global Template #{Time.current.to_i}",
          description: 'Global description',
          project_id: ''
        }
      }
    end

    template = SubtaskTemplate.last
    assert_nil template.project_id
  end

  def test_create_with_subtask_items
    # サブタスクアイテム付きテンプレートの作成テスト
    user = @admin
    priority = create(:issue_priority)
    tracker = create_tracker_with_status

    assert_difference 'SubtaskTemplate.count', 1 do
      assert_difference 'SubtaskTemplateItem.count', 2 do
        post :create, params: {
          subtask_template: {
            name: "Template with Items #{Time.current.to_i}",
            description: 'Template description',
            subtask_template_items_attributes: {
              '0' => {
                title: 'First Subtask',
                description: 'First description',
                assigned_to_id: user.id,
                priority_id: priority.id,
                tracker_id: tracker.id
              },
              '1' => {
                title: 'Second Subtask',
                description: 'Second description'
              }
            }
          }
        }
      end
    end

    template = SubtaskTemplate.last
    assert_equal 2, template.subtask_template_items.count

    first_item = template.subtask_template_items.first
    assert_equal 'First Subtask', first_item.title
    assert_equal user.id, first_item.assigned_to_id
    assert_equal priority.id, first_item.priority_id
    assert_equal tracker.id, first_item.tracker_id
  end

  def test_create_should_render_new_on_validation_error
    # バリデーションエラー時のテスト
    assert_no_difference 'SubtaskTemplate.count' do
      post :create, params: {
        subtask_template: {
          name: '', # 空の名前でバリデーションエラー
          description: 'Test description'
        }
      }
    end

    assert_response :success
    assert_template 'new'
    assert assigns(:template).errors[:name].present?
  end

  def test_show_should_display_template
    # 詳細表示のテスト
    get :show, params: { id: @template.id }

    assert_response :success
    assert_template 'show'
    assert_select 'h2', text: @template.name
  end

  def test_show_should_display_subtask_items
    # サブタスクアイテムの表示テスト
    get :show, params: { id: @template.id }

    assert_response :success
    assert_select '.subtask-item-detail', count: @template.subtask_template_items.count

    @template.subtask_template_items.each do |item|
      assert_select 'h4', text: /#{item.title}/
    end
  end

  def test_edit_should_display_form
    # 編集フォーム表示のテスト
    get :edit, params: { id: @template.id }

    assert_response :success
    assert_template 'edit'
    assert_select 'h2', text: 'Edit Subtask Template'
  end

  def test_update_should_modify_template
    # テンプレート更新のテスト
    new_name = "Updated Template Name #{Time.current.to_i}"

    patch :update, params: {
      id: @template.id,
      subtask_template: {
        name: new_name,
        description: 'Updated description'
      }
    }

    assert_redirected_to subtask_templates_path
    assert_equal 'Template was successfully updated.', flash[:notice]

    @template.reload
    assert_equal new_name, @template.name
    assert_equal 'Updated description', @template.description
  end

  def test_update_with_subtask_items_modification
    # サブタスクアイテム更新のテスト
    item = @template.subtask_template_items.first

    patch :update, params: {
      id: @template.id,
      subtask_template: {
        name: @template.name,
        subtask_template_items_attributes: {
          '0' => {
            id: item.id,
            title: 'Updated Subtask Title',
            description: 'Updated subtask description'
          }
        }
      }
    }

    assert_redirected_to subtask_templates_path

    item.reload
    assert_equal 'Updated Subtask Title', item.title
    assert_equal 'Updated subtask description', item.description
  end

  def test_update_with_subtask_items_deletion
    # サブタスクアイテム削除のテスト
    item = @template.subtask_template_items.first
    item_id = item.id

    patch :update, params: {
      id: @template.id,
      subtask_template: {
        name: @template.name,
        subtask_template_items_attributes: {
          '0' => {
            id: item.id,
            title: item.title,
            _destroy: '1'
          }
        }
      }
    }

    assert_redirected_to subtask_templates_path
    assert_nil SubtaskTemplateItem.find_by(id: item_id)
  end

  def test_update_should_render_edit_on_validation_error
    # 更新時のバリデーションエラーテスト
    patch :update, params: {
      id: @template.id,
      subtask_template: {
        name: '', # 空の名前でバリデーションエラー
        description: 'Updated description'
      }
    }

    assert_response :success
    assert_template 'edit'
    assert assigns(:template).errors[:name].present?
  end

  def test_destroy_should_delete_template
    # テンプレート削除のテスト
    template_id = @template.id

    assert_difference 'SubtaskTemplate.count', -1 do
      delete :destroy, params: { id: @template.id }
    end

    assert_redirected_to subtask_templates_path
    assert_equal 'Template was successfully deleted.', flash[:notice]
    assert_nil SubtaskTemplate.find_by(id: template_id)
  end

  def test_destroy_should_delete_associated_items
    # テンプレート削除時に関連アイテムも削除されることのテスト
    item_ids = @template.subtask_template_items.pluck(:id)

    delete :destroy, params: { id: @template.id }

    item_ids.each do |item_id|
      assert_nil SubtaskTemplateItem.find_by(id: item_id)
    end
  end

  def test_should_require_admin_access
    # 管理者権限が必要であることのテスト
    User.current = @user
    @request.session[:user_id] = @user.id

    get :index

    assert_response 403 # Forbidden
  end

  private

  def create_tracker_with_status
    status = create(:issue_status)
    create(:tracker, default_status: status)
  end

  def create_template_with_items
    template = create(:subtask_template)
    create(:subtask_template_item, subtask_template: template, title: "First Subtask")
    create(:subtask_template_item, subtask_template: template, title: "Second Subtask")

    template
  end
end
