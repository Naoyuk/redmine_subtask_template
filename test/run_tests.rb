#!/usr/bin/env ruby

# 簡単なテストランナー
ENV['RAILS_ENV'] = 'test'

# カレントディレクトリをプラグインのルートに設定
Dir.chdir(File.dirname(__FILE__) + '/..')

# パスの設定
$LOAD_PATH.unshift(File.expand_path('../../../..', __FILE__))
$LOAD_PATH.unshift(File.expand_path('..', __FILE__))

puts "Starting Subtask Template Plugin Tests..."
puts "Current directory: #{Dir.pwd}"
puts "Rails environment: #{ENV['RAILS_ENV']}"

begin
  # Railsアプリケーションを読み込み
  require File.expand_path('../../../../config/environment', __FILE__)
  
  # Railsテストヘルプを読み込み
  require 'rails/test_help'
  
  puts "Rails application loaded successfully."
  
  # データベース接続をテスト
  ActiveRecord::Base.connection
  puts "Database connection: OK"
  
  # モデルの読み込み確認
  require_relative '../app/models/subtask_template'
  require_relative '../app/models/subtask_template_item'
  puts "Plugin models loaded successfully."
  
rescue => e
  puts "Error during initialization: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end

# テストファイルを個別に実行
unit_test_files = Dir.glob('unit/**/*_test.rb')
functional_test_files = Dir.glob('functional/**/*_test.rb')
integration_test_files = Dir.glob('integration/**/*_test.rb')

test_files = unit_test_files + functional_test_files + integration_test_files

test_files.each do |file|
  test_path = File.join('test', file)
  
  puts "\n" + "="*60
  puts "Running: #{file}"
  puts "="*60
  
  if File.exist?(test_path)
    begin
      # テストファイルを実行
      system("ruby -I test #{test_path}")
      
      if $?.success?
        puts "✓ #{file} passed"
      else
        puts "✗ #{file} failed"
      end
    rescue => e
      puts "Error running #{file}: #{e.message}"
    end
  else
    puts "Test file not found: #{test_path}"
  end
end

puts "\nTest execution completed."
