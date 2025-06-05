require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplateItemTest < ActiveSupport::TestCase
  def setup
    setup_test_user
    setup_test_project
    @template = SubtaskTemplate.create!(
      name: 'Test Template',
      project: @project
    )
  end

  def test_create_item
    item = @template.subtask_template_items.new(
      title: 'Test Item',
      description: 'Test description'
    )
    
    assert item.save, "Item should be saved successfully"
    assert_equal 'Test Item', item.title
    assert_equal @template, item.subtask_template
  end

  def test_item_title_required
    item = @template.subtask_template_items.new(description: 'Test description')
    assert_not item.save, "Item should not be saved without title"
    assert_includes item.errors[:title], "can't be blank"
  end

  def test_item_title_length_validation
    long_title = 'a' * 256  # 255文字を超える
    item = @template.subtask_template_items.new(
      title: long_title,
      description: 'Test description'
    )
    
    assert_not item.save, "Item should not be saved with title longer than 255 characters"
    assert_includes item.errors[:title], "is too long (maximum is 255 characters)"
  end

  def test_item_description_length_validation
    long_description = 'a' * 65536  # 65535文字を超える
    item = @template.subtask_template_items.new(
      title: 'Test Item',
      description: long_description
    )
    
    assert_not item.save, "Item should not be saved with description longer than 65535 characters"
    assert_includes item.errors[:description], "is too long (maximum is 65535 characters)"
  end

  def test_item_belongs_to_template
    item = SubtaskTemplateItem.create!(
      subtask_template: @template,
      title: 'Belongs to Template'
    )
    
    assert_equal @template, item.subtask_template
    assert_includes @template.subtask_template_items, item
  end

  def test_item_with_assigned_user
    item = @template.subtask_template_items.create!(
      title: 'Assigned Item',
      assigned_to: @user
    )
    
    assert_equal @user, item.assigned_to
  end

  def test_item_with_tracker
    item = @template.subtask_template_items.create!(
      title: 'Tracker Item',
      tracker: default_tracker
    )
    
    assert_equal default_tracker, item.tracker
  end

  def test_item_with_priority
    item = @template.subtask_template_items.create!(
      title: 'Priority Item',
      priority: default_priority
    )
    
    assert_equal default_priority, item.priority
  end

  def test_item_ordered_scope
    item3 = @template.subtask_template_items.create!(title: 'Third', id: 3)
    item1 = @template.subtask_template_items.create!(title: 'First', id: 1)
    item2 = @template.subtask_template_items.create!(title: 'Second', id: 2)
    
    ordered_items = @template.subtask_template_items.ordered
    assert_equal [item1, item2, item3], ordered_items.to_a
  end

  def test_item_optional_associations
    # assigned_to、priority、trackerがnilでもエラーにならないことを確認
    item = @template.subtask_template_items.new(
      title: 'Optional Associations',
      assigned_to: nil,
      priority: nil,
      tracker: nil
    )
    
    assert item.save, "Item should be saved with nil associations"
    assert_nil item.assigned_to
    assert_nil item.priority
    assert_nil item.tracker
  end

  def test_item_position_default
    item = @template.subtask_template_items.create!(title: 'Position Test')
    assert_equal 0, item.position, "Default position should be 0"
  end

  def test_item_position_custom
    item = @template.subtask_template_items.create!(
      title: 'Custom Position',
      position: 5
    )
    assert_equal 5, item.position
  end
end
