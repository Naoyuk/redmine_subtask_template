require File.expand_path('../../test_helper', __FILE__)

class SubtaskTemplateTest < ActiveSupport::TestCase
  
  def test_should_create_template
    # 基本的なテンプレート作成のテスト
    template = SubtaskTemplate.new(
      name: "Test Template",
      description: "Test description"
    )
    
    assert template.save
    assert_equal "Test Template", template.name
    assert_equal "Test description", template.description
    assert_nil template.project_id
  end
  
  def test_should_require_name
    # nameが必須であることのテスト
    template = SubtaskTemplate.new(description: "Test description")
    
    assert_not template.save
    assert template.errors[:name].present?
  end
  
  def test_should_validate_name_length
    # nameの長さ制限のテスト
    template = SubtaskTemplate.new(name: "a" * 256)
    
    assert_not template.save
    assert template.errors[:name].present?
  end
  
  def test_should_validate_name_uniqueness_globally
    # グローバルテンプレートでのname一意性テスト
    SubtaskTemplate.create!(name: "Unique Template")
    
    template = SubtaskTemplate.new(name: "Unique Template")
    assert_not template.save
    assert template.errors[:name].present?
  end
  
  def test_should_validate_name_uniqueness_within_project
    # プロジェクト内でのname一意性テスト
    if defined?(Project)
      project = Project.create!(
        name: "Test Project", 
        identifier: "test-project-#{Time.current.to_i}"
      )
      
      SubtaskTemplate.create!(name: "Project Template", project: project)
      
      template = SubtaskTemplate.new(name: "Project Template", project: project)
      assert_not template.save
      assert template.errors[:name].present?
    end
  end
  
  def test_should_allow_same_name_across_different_projects
    # 異なるプロジェクト間では同じ名前を許可
    if defined?(Project)
      project1 = Project.create!(
        name: "Project 1", 
        identifier: "project-1-#{Time.current.to_i}"
      )
      project2 = Project.create!(
        name: "Project 2", 
        identifier: "project-2-#{Time.current.to_i}"
      )
      
      template1 = SubtaskTemplate.create!(name: "Same Name", project: project1)
      template2 = SubtaskTemplate.new(name: "Same Name", project: project2)
      
      assert template2.save
    end
  end
  
  def test_should_allow_same_name_for_global_and_project_templates
    # グローバルテンプレートとプロジェクトテンプレートで同じ名前を許可
    if defined?(Project)
      project = Project.create!(
        name: "Test Project", 
        identifier: "test-project-#{Time.current.to_i}"
      )
      
      global_template = SubtaskTemplate.create!(name: "Template Name")
      project_template = SubtaskTemplate.new(name: "Template Name", project: project)
      
      assert project_template.save
    end
  end
  
  def test_display_name_for_global_template
    # グローバルテンプレートのdisplay_nameテスト
    template = SubtaskTemplate.create!(name: "Global Template")
    
    assert_equal "Global Template (Global)", template.display_name
  end
  
  def test_display_name_for_project_template
    # プロジェクトテンプレートのdisplay_nameテスト
    if defined?(Project)
      project = Project.create!(
        name: "Test Project", 
        identifier: "test-project-#{Time.current.to_i}"
      )
      
      template = SubtaskTemplate.create!(name: "Project Template", project: project)
      
      assert_equal "Project Template (Test Project)", template.display_name
    end
  end
  
  def test_global_scope
    # globalスコープのテスト
    global_template = SubtaskTemplate.create!(name: "Global Template")
    
    if defined?(Project)
      project = Project.create!(
        name: "Test Project", 
        identifier: "test-project-#{Time.current.to_i}"
      )
      project_template = SubtaskTemplate.create!(name: "Project Template", project: project)
      
      global_templates = SubtaskTemplate.global
      assert_includes global_templates, global_template
      assert_not_includes global_templates, project_template
    else
      global_templates = SubtaskTemplate.global
      assert_includes global_templates, global_template
    end
  end
  
  def test_for_project_scope
    # for_projectスコープのテスト
    if defined?(Project)
      project = Project.create!(
        name: "Test Project", 
        identifier: "test-project-#{Time.current.to_i}"
      )
      
      global_template = SubtaskTemplate.create!(name: "Global Template")
      project_template = SubtaskTemplate.create!(name: "Project Template", project: project)
      
      project_templates = SubtaskTemplate.for_project(project)
      assert_includes project_templates, project_template
      assert_not_includes project_templates, global_template
    end
  end
  
  def test_association_with_subtask_template_items
    # SubtaskTemplateItemとの関連テスト
    template = SubtaskTemplate.create!(name: "Template with Items")
    
    item1 = template.subtask_template_items.create!(title: "Subtask 1")
    item2 = template.subtask_template_items.create!(title: "Subtask 2")
    
    assert_equal 2, template.subtask_template_items.count
    assert_includes template.subtask_template_items, item1
    assert_includes template.subtask_template_items, item2
  end
  
  def test_should_destroy_dependent_items
    # テンプレート削除時に関連するアイテムも削除されることのテスト
    template = SubtaskTemplate.create!(name: "Template to Delete")
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
end
