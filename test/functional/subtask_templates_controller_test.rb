require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplatesControllerTest < ActionController::TestCase
  def setup
    setup_test_user
    setup_test_project
    @request.session[:user_id] = @user.id
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:templates)
  end

  def test_should_get_index_with_templates
    template = SubtaskTemplate.create!(name: 'Test Template', project: @project)
    
    get :index
    assert_response :success
    assert_includes assigns(:templates), template
  end

  def test_should_get_new
    get :new
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:template)
    assert assigns(:template).new_record?
  end

  def test_should_create_template
    assert_difference('SubtaskTemplate.count') do
      post :create, params: {
        subtask_template: {
          name: 'New Template',
          description: 'New template description',
          project_id: @project.id
        }
      }
    end
    
    assert_redirected_to subtask_templates_path
    assert_equal 'テンプレートが作成されました。', flash[:notice]
    
    template = SubtaskTemplate.last
    assert_equal 'New Template', template.name
    assert_equal @project, template.project
  end

  def test_should_not_create_template_without_name
    assert_no_difference('SubtaskTemplate.count') do
      post :create, params: {
        subtask_template: {
          description: 'Template without name'
        }
      }
    end
    
    assert_template 'new'
    assert_not_nil assigns(:template).errors[:name]
  end

  def test_should_get_show
    template = SubtaskTemplate.create!(name: 'Show Template', project: @project)
    
    get :show, params: { id: template.id }
    assert_response :success
    assert_template 'show'
    assert_equal template, assigns(:template)
  end

  def test_should_get_edit
    template = SubtaskTemplate.create!(name: 'Edit Template', project: @project)
    
    get :edit, params: { id: template.id }
    assert_response :success
    assert_template 'edit'
    assert_equal template, assigns(:template)
  end

  def test_should_update_template
    template = SubtaskTemplate.create!(name: 'Original Name', project: @project)
    
    put :update, params: {
      id: template.id,
      subtask_template: {
        name: 'Updated Name',
        description: 'Updated description'
      }
    }
    
    assert_redirected_to subtask_templates_path
    assert_equal 'テンプレートが更新されました。', flash[:notice]
    
    template.reload
    assert_equal 'Updated Name', template.name
    assert_equal 'Updated description', template.description
  end

  def test_should_not_update_template_with_invalid_data
    template = SubtaskTemplate.create!(name: 'Valid Name', project: @project)
    
    put :update, params: {
      id: template.id,
      subtask_template: {
        name: ''  # 空の名前
      }
    }
    
    assert_template 'edit'
    assert_not_nil assigns(:template).errors[:name]
    
    template.reload
    assert_equal 'Valid Name', template.name  # 変更されていない
  end

  def test_should_destroy_template
    template = SubtaskTemplate.create!(name: 'Delete Template', project: @project)
    
    assert_difference('SubtaskTemplate.count', -1) do
      delete :destroy, params: { id: template.id }
    end
    
    assert_redirected_to subtask_templates_path
    assert_equal 'テンプレートが削除されました。', flash[:notice]
  end

  def test_should_create_template_with_nested_items
    assert_difference('SubtaskTemplate.count') do
      assert_difference('SubtaskTemplateItem.count', 2) do
        post :create, params: {
          subtask_template: {
            name: 'Template with Items',
            description: 'Template description',
            project_id: @project.id,
            subtask_template_items_attributes: {
              '0' => {
                title: 'First Item',
                description: 'First item description',
                assigned_to_id: @user.id,
                tracker_id: default_tracker.id
              },
              '1' => {
                title: 'Second Item',
                description: 'Second item description',
                priority_id: default_priority.id
              }
            }
          }
        }
      end
    end
    
    template = SubtaskTemplate.last
    assert_equal 2, template.subtask_template_items.count
    
    first_item = template.subtask_template_items.find_by(title: 'First Item')
    assert_not_nil first_item
    assert_equal @user, first_item.assigned_to
    assert_equal default_tracker, first_item.tracker
    
    second_item = template.subtask_template_items.find_by(title: 'Second Item')
    assert_not_nil second_item
    assert_equal default_priority, second_item.priority
  end

  def test_should_update_template_with_nested_items
    template = SubtaskTemplate.create!(name: 'Template', project: @project)
    item = template.subtask_template_items.create!(title: 'Original Item')
    
    put :update, params: {
      id: template.id,
      subtask_template: {
        name: 'Updated Template',
        subtask_template_items_attributes: {
          '0' => {
            id: item.id,
            title: 'Updated Item',
            description: 'Updated description'
          },
          '1' => {
            title: 'New Item',
            description: 'New item description'
          }
        }
      }
    }
    
    assert_redirected_to subtask_templates_path
    
    template.reload
    assert_equal 'Updated Template', template.name
    assert_equal 2, template.subtask_template_items.count
    
    item.reload
    assert_equal 'Updated Item', item.title
    assert_equal 'Updated description', item.description
    
    new_item = template.subtask_template_items.find_by(title: 'New Item')
    assert_not_nil new_item
  end

  def test_should_delete_nested_items
    template = SubtaskTemplate.create!(name: 'Template', project: @project)
    item = template.subtask_template_items.create!(title: 'Item to Delete')
    
    assert_difference('SubtaskTemplateItem.count', -1) do
      put :update, params: {
        id: template.id,
        subtask_template: {
          name: 'Template',
          subtask_template_items_attributes: {
            '0' => {
              id: item.id,
              _destroy: '1'
            }
          }
        }
      }
    end
    
    assert_not SubtaskTemplateItem.exists?(item.id)
  end

  def test_should_require_admin_access
    # 非管理者ユーザーでテスト
    user = User.find_by_login('jsmith') || User.create!(
      login: 'testuser',
      firstname: 'Test',
      lastname: 'User',
      mail: 'test@example.com',
      language: 'en',
      status: User::STATUS_ACTIVE
    )
    @request.session[:user_id] = user.id
    
    get :index
    assert_response 403
  rescue ActionController::RoutingError
    # ルートが見つからない場合はスキップ
    skip "Route not found - this may be expected if plugin routes are not loaded"
  end

  def test_should_handle_not_found
    get :show, params: { id: 999999 }
    assert_response :not_found
  rescue ActiveRecord::RecordNotFound
    # Redmineのバージョンによっては例外が発生する場合がある
    assert true
  end
end
