require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplateItemTest < ActiveSupport::TestCase
  
  def setup
    @template = create(:subtask_template, name: "Test Template")
  end
  
  def test_should_create_item
    # Factoryが有効であることのテスト
    item = build(:subtask_template_item, subtask_template: @template)

    assert item.save
    assert_equal @template, item.subtask_template
  end
  
  def test_should_require_title
    # titleが必須であることのテスト
    item = build(:subtask_template_item, title: nil)

    assert_not item.save
    assert item.errors[:title].present?
  end
  
  def test_should_validate_title_length
    # titleの長さ制限のテスト
    item = build(:subtask_template_item, title: "a" * 256)

    assert_not item.save
    assert item.errors[:title].present?
  end
  
  def test_should_validate_description_length
    # descriptionの長さ制限のテスト
    item = build(:subtask_template_item, description: "a" * 65536)

    assert_not item.save
    assert item.errors[:description].present?
  end
  
  def test_should_allow_nil_description
    # descriptionがnilでも保存できることのテスト
    item = build(:subtask_template_item, description: nil)

    assert item.save
  end
  
  def test_should_allow_empty_description
    # descriptionが空文字でも保存できることのテスト
    item = build(:subtask_template_item, description: "")

    assert item.save
  end
  
  def test_association_with_assigned_to_user
    # assigned_toとの関連テスト
    if defined?(User)
      user = create(:user)
      item = create(:subtask_template_item, assigned_to: user)

      assert_equal user, item.assigned_to
    end
  end
  
  def test_association_with_priority
    # priorityとの関連テスト
    if defined?(IssuePriority)
      priority = create(:issue_priority)
      item = create(:subtask_template_item, priority: priority)

      assert_equal priority, item.priority
    end
  end
  
  def test_association_with_tracker
    # trackerとの関連テスト
    if defined?(Tracker)
      tracker = create(:tracker)
      item = create(:subtask_template_item, tracker: tracker)

      assert_equal tracker, item.tracker
    end
  end
  
  def test_ordered_scope
    # orderedスコープのテスト
    item1 = create(:subtask_template_item, subtask_template: @template, title: "First Item")
    item2 = create(:subtask_template_item, subtask_template: @template, title: "Second Item")

    ordered_items = @template.subtask_template_items.ordered

    # IDの順序で並んでいることを確認
    assert_equal item1.id, ordered_items.first.id
    assert_equal item2.id, ordered_items.last.id
  end
  
  def test_should_allow_nil_foreign_keys
    # 外部キーがnilでも保存できることのテスト
    item = create(:subtask_template_item, assigned_to_id: nil, priority_id: nil, tracker_id: nil)

    assert item.persisted?
    assert_nil item.assigned_to_id
    assert_nil item.priority_id
    assert_nil item.tracker_id
  end
  
  def test_should_handle_invalid_foreign_keys
    # 無効な外部キーでもバリデーションエラーにならないことのテスト（外部キー制約がデータベースレベルで処理される）
    item = build(:subtask_template_item, assigned_to_id: 0, priority_id: 0, tracker_id: 0)

    # バリデーションは通るが、保存時にデータベースエラーが発生する可能性
    assert item.valid?
  end
end
