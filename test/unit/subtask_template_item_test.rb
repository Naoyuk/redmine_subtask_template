require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplateItemTest < ActiveSupport::TestCase
  
  def setup
    @template = SubtaskTemplate.create!(name: "Test Template")
  end
  
  def test_should_create_item
    # 基本的なアイテム作成のテスト
    item = SubtaskTemplateItem.new(
      subtask_template: @template,
      title: "Test Subtask",
      description: "Test description"
    )
    
    assert item.save
    assert_equal "Test Subtask", item.title
    assert_equal "Test description", item.description
    assert_equal @template, item.subtask_template
  end
  
  def test_should_require_title
    # titleが必須であることのテスト
    item = SubtaskTemplateItem.new(
      subtask_template: @template,
      description: "Description without title"
    )
    
    assert_not item.save
    assert item.errors[:title].present?
  end
  
  def test_should_validate_title_length
    # titleの長さ制限のテスト
    item = SubtaskTemplateItem.new(
      subtask_template: @template,
      title: "a" * 256
    )
    
    assert_not item.save
    assert item.errors[:title].present?
  end
  
  def test_should_validate_description_length
    # descriptionの長さ制限のテスト
    item = SubtaskTemplateItem.new(
      subtask_template: @template,
      title: "Valid Title",
      description: "a" * 65536  # 65535文字を超える
    )
    
    assert_not item.save
    assert item.errors[:description].present?
  end
  
  def test_should_allow_nil_description
    # descriptionがnilでも保存できることのテスト
    item = SubtaskTemplateItem.new(
      subtask_template: @template,
      title: "Title Only",
      description: nil
    )
    
    assert item.save
  end
  
  def test_should_allow_empty_description
    # descriptionが空文字でも保存できることのテスト
    item = SubtaskTemplateItem.new(
      subtask_template: @template,
      title: "Title Only",
      description: ""
    )
    
    assert item.save
  end
  
  def test_association_with_assigned_to_user
    # assigned_toとの関連テスト（Userが存在する場合）
    if defined?(User)
      user = User.first || User.create!(
        login: "testuser#{Time.current.to_i}",
        firstname: "Test",
        lastname: "User",
        mail: "test#{Time.current.to_i}@example.com"
      )
      
      item = SubtaskTemplateItem.create!(
        subtask_template: @template,
        title: "Assigned Subtask",
        assigned_to: user
      )
      
      assert_equal user, item.assigned_to
    end
  end
  
  def test_association_with_priority
    # priorityとの関連テスト（IssuePriorityが存在する場合）
    if defined?(IssuePriority)
      priority = IssuePriority.first || IssuePriority.create!(
        name: "High Priority #{Time.current.to_i}"
      )
      
      item = SubtaskTemplateItem.create!(
        subtask_template: @template,
        title: "Priority Subtask",
        priority: priority
      )
      
      assert_equal priority, item.priority
    end
  end
  
  def test_association_with_tracker
    # trackerとの関連テスト（Trackerが存在する場合）
    if defined?(Tracker)
      # 既存のトラッカーを使用するか、新しく作成
      tracker = Tracker.first
      unless tracker
        # IssueStatusが必要な場合は作成
        status = IssueStatus.first || IssueStatus.create!(
          name: "New #{Time.current.to_i}"
        )
        tracker = Tracker.create!(
          name: "Test Tracker #{Time.current.to_i}",
          default_status: status
        )
      end
      
      item = SubtaskTemplateItem.create!(
        subtask_template: @template,
        title: "Tracker Subtask",
        tracker: tracker
      )
      
      assert_equal tracker, item.tracker
    end
  end
  
  def test_ordered_scope
    # orderedスコープのテスト
    item1 = SubtaskTemplateItem.create!(
      subtask_template: @template,
      title: "First Item"
    )
    item2 = SubtaskTemplateItem.create!(
      subtask_template: @template,
      title: "Second Item"
    )
    
    ordered_items = @template.subtask_template_items.ordered
    
    # IDの順序で並んでいることを確認
    assert_equal item1.id, ordered_items.first.id
    assert_equal item2.id, ordered_items.last.id
  end
  
  def test_should_allow_nil_foreign_keys
    # 外部キーがnilでも保存できることのテスト
    item = SubtaskTemplateItem.create!(
      subtask_template: @template,
      title: "Minimal Subtask",
      assigned_to_id: nil,
      priority_id: nil,
      tracker_id: nil
    )
    
    assert item.persisted?
    assert_nil item.assigned_to_id
    assert_nil item.priority_id
    assert_nil item.tracker_id
  end
  
  def test_should_handle_invalid_foreign_keys
    # 無効な外部キーでもバリデーションエラーにならないことのテスト
    # （外部キー制約がデータベースレベルで処理される）
    item = SubtaskTemplateItem.new(
      subtask_template: @template,
      title: "Test Subtask",
      assigned_to_id: 99999,  # 存在しないID
      priority_id: 99999,
      tracker_id: 99999
    )
    
    # バリデーションは通るが、保存時にデータベースエラーが発生する可能性
    assert item.valid?
  end
end
