#!/usr/bin/env ruby

# 最小限のテスト - mochaに依存しない
ENV['RAILS_ENV'] = 'test'

# 既にRailsが読み込まれているかチェック
unless defined?(Rails)
  # Railsアプリケーションを読み込み
  require File.expand_path('../../../../config/environment', __FILE__)
end

require 'minitest/autorun'

class MinimalSubtaskTemplateTest < Minitest::Test
  def setup
    @user = User.first || User.create!(
      login: 'testuser',
      firstname: 'Test',
      lastname: 'User',
      mail: 'test@example.com'
    )
    
    @project = Project.first || Project.create!(
      name: 'Test Project',
      identifier: 'test-project'
    )
  end

  def test_subtask_template_model_exists
    assert defined?(SubtaskTemplate), "SubtaskTemplate model should be defined"
  end

  def test_subtask_template_item_model_exists
    assert defined?(SubtaskTemplateItem), "SubtaskTemplateItem model should be defined"
  end

  def test_create_simple_template
    template = SubtaskTemplate.new(
      name: 'Test Template',
      description: 'Test description'
    )
    
    assert template.valid?, "Template should be valid with name"
    assert template.save, "Template should be saved"
  end

  def test_template_requires_name
    template = SubtaskTemplate.new(description: 'No name')
    
    refute template.valid?, "Template should not be valid without name"
    assert_includes template.errors[:name], "can't be blank"
  end

  def test_create_template_with_project
    template = SubtaskTemplate.new(
      name: 'Project Template',
      project: @project
    )
    
    assert template.save, "Template with project should be saved"
    assert_equal @project, template.project
  end

  def test_create_subtask_item
    template = SubtaskTemplate.create!(
      name: 'Template with Items',
      project: @project
    )

    item = template.subtask_template_items.new(
      title: 'Test Item',
      description: 'Test item description'
    )
    
    assert item.save, "Subtask item should be saved"
    assert_equal template, item.subtask_template
  end

  def test_subtask_item_requires_title
    template = SubtaskTemplate.create!(name: 'Template', project: @project)
    item = template.subtask_template_items.new(description: 'No title')
    
    refute item.valid?, "Subtask item should not be valid without title"
    assert_includes item.errors[:title], "can't be blank"
  end

  def test_template_associations
    template = SubtaskTemplate.create!(name: 'Association Test', project: @project)
    
    # has_many association
    assert_respond_to template, :subtask_template_items
    
    # belongs_to association  
    assert_respond_to template, :project
  end

  def test_item_associations
    template = SubtaskTemplate.create!(name: 'Item Association Test', project: @project)
    item = template.subtask_template_items.create!(title: 'Test Item')
    
    # belongs_to association
    assert_respond_to item, :subtask_template
    assert_respond_to item, :assigned_to
    assert_respond_to item, :tracker
    assert_respond_to item, :priority
  end

  def teardown
    # テスト後のクリーンアップ
    SubtaskTemplateItem.delete_all
    SubtaskTemplate.delete_all
  end
end

# テストを実行（単体実行時のみ）
if __FILE__ == $0
  puts "Running minimal subtask template tests..."
  Minitest.run
end
