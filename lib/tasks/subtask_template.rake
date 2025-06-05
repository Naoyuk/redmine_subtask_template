namespace :subtask_template do
  desc "Run all tests for subtask_template plugin"
  task :test => :environment do
    Rails.env = 'test'
    
    # 前提条件のチェック
    begin
      ActiveRecord::Base.connection
    rescue => e
      puts "Database connection failed: #{e.message}"
      puts "Please run: bundle exec rake subtask_template:setup_test RAILS_ENV=test"
      exit 1
    end
    
    # テストファイルのパスを取得
    plugin_path = Rails.root.join('plugins/subtask_template')
    test_files = Dir[plugin_path.join('test/**/*_test.rb')]
    
    puts "Running subtask_template plugin tests..."
    puts "Found #{test_files.length} test files"
    
    # 各テストファイルを個別に実行
    test_files.each do |file|
      puts "\n" + "="*50
      puts "Running: #{File.basename(file)}"
      puts "="*50
      
      begin
        # テストファイルを読み込み
        load file
      rescue => e
        puts "Error loading #{file}: #{e.message}"
        puts e.backtrace.first(5)
        next
      end
    end
    
    puts "\nTest execution completed."
  end

  desc "Run unit tests only"
  task :test_units => :environment do
    Rails.env = 'test'
    
    plugin_path = Rails.root.join('plugins/subtask_template')
    test_files = Dir[plugin_path.join('test/unit/**/*_test.rb')]
    
    puts "Running subtask_template unit tests..."
    
    test_files.each do |file|
      puts "Running: #{File.basename(file)}"
      begin
        load file
      rescue => e
        puts "Error: #{e.message}"
      end
    end
  end

  desc "Run functional tests only"
  task :test_functionals => :environment do
    Rails.env = 'test'
    
    plugin_path = Rails.root.join('plugins/subtask_template')
    test_files = Dir[plugin_path.join('test/functional/**/*_test.rb')]
    
    puts "Running subtask_template functional tests..."
    
    test_files.each do |file|
      puts "Running: #{File.basename(file)}"
      begin
        load file
      rescue => e
        puts "Error: #{e.message}"
      end
    end
  end

  desc "Run integration tests only"
  task :test_integration => :environment do
    Rails.env = 'test'
    
    plugin_path = Rails.root.join('plugins/subtask_template')
    test_files = Dir[plugin_path.join('test/integration/**/*_test.rb')]
    
    puts "Running subtask_template integration tests..."
    
    test_files.each do |file|
      puts "Running: #{File.basename(file)}"
      begin
        load file
      rescue => e
        puts "Error: #{e.message}"
      end
    end
  end

  desc "Setup test database for plugin"
  task :setup_test => :environment do
    Rails.env = 'test'
    
    puts "Setting up test database for subtask_template plugin..."
    
    # テスト用データベースの作成とマイグレーション
    begin
      Rake::Task['db:create'].invoke
    rescue => e
      puts "db:create failed or already exists: #{e.message}"
    end
    
    begin
      Rake::Task['db:migrate'].invoke
    rescue => e
      puts "db:migrate failed: #{e.message}"
    end
    
    begin
      Rake::Task['redmine:plugins:migrate'].invoke
    rescue => e
      puts "plugins:migrate failed: #{e.message}"
    end
    
    puts "Test database setup completed."
  end

  desc "Clean test database"
  task :clean_test => :environment do
    Rails.env = 'test'
    
    puts "Cleaning test database..."
    
    # プラグインのマイグレーションをロールバック
    begin
      system("bundle exec rake redmine:plugins:migrate NAME=subtask_template VERSION=0 RAILS_ENV=test")
    rescue => e
      puts "Clean failed: #{e.message}"
    end
    
    puts "Test database cleaned."
  end

  desc "Run single test file"
  task :test_file, [:file] => :environment do |t, args|
    Rails.env = 'test'
    
    file_path = args[:file]
    unless file_path
      puts "Usage: bundle exec rake subtask_template:test_file[path/to/test_file.rb]"
      exit 1
    end
    
    plugin_path = Rails.root.join('plugins/subtask_template')
    full_path = plugin_path.join(file_path)
    
    if File.exist?(full_path)
      puts "Running: #{file_path}"
      load full_path
    else
      puts "Test file not found: #{full_path}"
      exit 1
    end
  end
end
