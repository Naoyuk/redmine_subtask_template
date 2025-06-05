# テストヘルパー
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

# FactoryBotの設定
begin
  require 'factory_bot'
  require File.expand_path('../factories', __FILE__)
  
  class ActiveSupport::TestCase
    include FactoryBot::Syntax::Methods
    
    # テスト前にデータベースをクリーンアップ
    setup do
      SubtaskTemplateItem.delete_all
      SubtaskTemplate.delete_all
    end
  end
rescue LoadError
  # FactoryBotが利用できない場合のフォールバック
  puts "FactoryBot not available, using manual test data creation"
  
  class ActiveSupport::TestCase
    # テスト前にデータベースをクリーンアップ
    setup do
      SubtaskTemplateItem.delete_all
      SubtaskTemplate.delete_all
    end
    
    private
    
    # 手動でテストデータを作成するヘルパーメソッド
    def create_subtask_template(attributes = {})
      default_attributes = {
        name: "Test Template #{Time.current.to_i}",
        description: "Test description"
      }
      SubtaskTemplate.create!(default_attributes.merge(attributes))
    end
    
    def create_subtask_template_item(template, attributes = {})
      default_attributes = {
        title: "Test Subtask #{Time.current.to_i}",
        description: "Test subtask description"
      }
      template.subtask_template_items.create!(default_attributes.merge(attributes))
    end
  end
end
