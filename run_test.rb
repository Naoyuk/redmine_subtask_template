#!/usr/bin/env ruby

# 完全なテストランナー
ENV['RAILS_ENV'] = 'test'

# Redmineのルートディレクトリを動的に検索
current_dir = Dir.pwd
redmine_root = nil

5.times do
  config_path = File.join(current_dir, 'config', 'environment.rb')
  if File.exist?(config_path)
    redmine_root = current_dir
    break
  end
  current_dir = File.dirname(current_dir)
end

if redmine_root.nil?
  puts "Error: Could not find Redmine root directory"
  exit 1
end

puts "=== Subtask Template Plugin Test Suite ==="
puts "Redmine root: #{redmine_root}"
puts "Rails environment: #{ENV['RAILS_ENV']}"
puts "Current directory: #{Dir.pwd}"

# 環境を読み込み
puts "\nLoading Rails environment..."
require File.join(redmine_root, 'config', 'environment.rb')
require 'rails/test_help'
require 'minitest/autorun'

puts "✓ Environment loaded successfully"
puts "Rails.env: #{Rails.env}"

# データベース接続テスト
begin
  ActiveRecord::Base.connection.execute("SELECT 1")
  puts "✓ Database connection successful"
rescue => e
  puts "✗ Database connection failed: #{e.message}"
  exit 1
end

# プラグインディレクトリの設定
plugin_dir = File.join(redmine_root, 'plugins', 'subtask_template')
test_dir = File.join(plugin_dir, 'test')

# テストファイルのカテゴリ
test_categories = {
  'Unit Tests' => 'unit',
  'Functional Tests' => 'functional', 
  'Integration Tests' => 'integration'
}

# 実行する個別テストファイル
specific_tests = [
  'test/minimal_test.rb'
]

puts "\n=== Running Specific Tests ==="

# minimal_testを最初に実行
specific_tests.each do |test_file|
  test_path = File.join(plugin_dir, test_file)
  
  if File.exist?(test_path)
    puts "\n--- Running #{test_file} ---"
    begin
      load test_path
    rescue => e
      puts "Error running #{test_file}: #{e.message}"
      puts e.backtrace.first(3)
    end
  else
    puts "Test file not found: #{test_path}"
  end
end

puts "\n=== Running Categorized Tests ==="

# カテゴリ別にテスト実行
test_categories.each do |category_name, category_dir|
  category_path = File.join(test_dir, category_dir)
  
  unless Dir.exist?(category_path)
    puts "\n--- #{category_name} ---"
    puts "Directory not found: #{category_path}"
    next
  end
  
  test_files = Dir[File.join(category_path, '*_test.rb')]
  
  if test_files.empty?
    puts "\n--- #{category_name} ---"
    puts "No test files found in #{category_path}"
    next
  end
  
  puts "\n--- #{category_name} ---"
  puts "Found #{test_files.length} test file(s)"
  
  test_files.each do |test_file|
    test_name = File.basename(test_file)
    puts "\nRunning: #{test_name}"
    
    begin
      # test_helperを先に読み込む
      helper_path = File.join(test_dir, 'test_helper.rb')
      require helper_path if File.exist?(helper_path) && !$loaded_test_helper
      $loaded_test_helper = true
      
      # テストファイルを実行
      load test_file
      puts "✓ #{test_name} loaded successfully"
      
    rescue => e
      puts "✗ #{test_name} failed to load"
      puts "Error: #{e.message}"
      puts "Backtrace:"
      puts e.backtrace.first(5)
    end
  end
end

puts "\n=== Running MiniTest Suite ==="

# MiniTestランナーでテストを実行
begin
  result = Minitest.run([])
  puts "\n=== Test Results ==="
  if result == 0
    puts "✓ All tests passed!"
  else
    puts "✗ Some tests failed (exit code: #{result})"
  end
rescue => e
  puts "Error running test suite: #{e.message}"
end

puts "\n=== Test Suite Complete ==="
