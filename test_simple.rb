#!/usr/bin/env ruby

# より確実なパス指定でのテスト
ENV['RAILS_ENV'] = 'test'

# カレントディレクトリの確認
puts "Current directory: #{Dir.pwd}"
puts "File location: #{__FILE__}"
puts "Expanded file path: #{File.expand_path(__FILE__)}"

# Redmineのルートディレクトリを検索
current_dir = Dir.pwd
redmine_root = nil

# 上位ディレクトリを検索してconfig/environment.rbを探す
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

puts "Redmine root found: #{redmine_root}"
environment_path = File.join(redmine_root, 'config', 'environment.rb')
puts "Loading environment: #{environment_path}"

# 環境を読み込み
require environment_path
require 'minitest/autorun'

puts "Environment loaded successfully!"
puts "Rails.env: #{Rails.env}"
puts "Rails.root: #{Rails.root}"

# モデルの存在確認
begin
  puts "Checking SubtaskTemplate model..."
  if defined?(SubtaskTemplate)
    puts "✓ SubtaskTemplate model is available"
  else
    puts "✗ SubtaskTemplate model not found"
  end

  puts "Checking SubtaskTemplateItem model..."
  if defined?(SubtaskTemplateItem)
    puts "✓ SubtaskTemplateItem model is available"
  else
    puts "✗ SubtaskTemplateItem model not found"
  end
rescue => e
  puts "Error checking models: #{e.message}"
end

# データベース接続テスト
begin
  puts "Testing database connection..."
  ActiveRecord::Base.connection.execute("SELECT 1")
  puts "✓ Database connection successful"
rescue => e
  puts "✗ Database connection failed: #{e.message}"
end

# 簡単なテスト実行
class QuickTest < Minitest::Test
  def test_environment_loaded
    assert defined?(Rails), "Rails should be defined"
    assert_equal 'test', Rails.env, "Should be in test environment"
  end

  def test_database_connection
    assert ActiveRecord::Base.connection, "Database should be connected"
  end

  def test_models_exist
    assert defined?(SubtaskTemplate), "SubtaskTemplate should be defined"
    assert defined?(SubtaskTemplateItem), "SubtaskTemplateItem should be defined"
  end

  def test_create_template
    template = SubtaskTemplate.new(name: 'Quick Test Template')
    assert template.valid?, "Template should be valid: #{template.errors.full_messages}"
  end
end

puts "\nRunning quick tests..."
