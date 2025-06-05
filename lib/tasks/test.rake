# プラグインテスト用のRakeタスク
namespace :subtask_template do
  namespace :test do
    desc 'Run all subtask_template plugin tests'
    task :all => :environment do
      Dir.chdir("#{Rails.root}/plugins/subtask_template") do
        puts "Running unit tests..."
        system("ruby -Itest test/unit/subtask_template_test.rb")
        system("ruby -Itest test/unit/subtask_template_item_test.rb")
        
        puts "\nRunning functional tests..."
        system("ruby -Itest test/functional/subtask_templates_controller_test.rb")
        
        puts "\nRunning integration tests..."
        system("ruby -Itest test/integration/subtask_templates_integration_test.rb")
      end
    end
    
    desc 'Run subtask_template model tests'
    task :models => :environment do
      Dir.chdir("#{Rails.root}/plugins/subtask_template") do
        puts "Running unit tests..."
        system("ruby -Itest test/unit/subtask_template_test.rb")
        system("ruby -Itest test/unit/subtask_template_item_test.rb")
      end
    end
    
    desc 'Run subtask_template controller tests'
    task :controllers => :environment do
      Dir.chdir("#{Rails.root}/plugins/subtask_template") do
        puts "Running functional tests..."
        system("ruby -Itest test/functional/subtask_templates_controller_test.rb")
      end
    end
    
    desc 'Run subtask_template integration tests'
    task :integration => :environment do
      Dir.chdir("#{Rails.root}/plugins/subtask_template") do
        puts "Running integration tests..."
        system("ruby -Itest test/integration/subtask_templates_integration_test.rb")
      end
    end
    
    desc 'Run specific test file'
    task :file, [:filename] => :environment do |t, args|
      filename = args[:filename] || 'subtask_template_test.rb'

      test_type = if filename.include?('integration')
                    'integration'
                  elsif filename.include?('controller')
                    'functional'
                  else
                    'unit'
                  end
      
      Dir.chdir("#{Rails.root}/plugins/subtask_template") do
        system("ruby -Itest test/#{test_type}/#{filename}")
      end
    end
  end
end
