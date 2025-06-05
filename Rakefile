# Rakeタスクファイル
require 'rake'
require 'rake/testtask'

desc 'Run all subtask_template plugin tests'
task :test do
  Rake::Task['test:units'].invoke
  Rake::Task['test:functionals'].invoke
  Rake::Task['test:integration'].invoke
end

namespace :test do
  desc 'Run unit tests'
  Rake::TestTask.new(:units => "test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'plugins/subtask_template/test/unit/**/*_test.rb'
    t.verbose = true
  end

  desc 'Run functional tests'
  Rake::TestTask.new(:functionals => "test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'plugins/subtask_template/test/functional/**/*_test.rb'
    t.verbose = true
  end

  desc 'Run integration tests'
  Rake::TestTask.new(:integration => "test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'plugins/subtask_template/test/integration/**/*_test.rb'
    t.verbose = true
  end

  desc 'Prepare test database'
  task :prepare do
    # テストデータベースの準備
    unless Rake::Task.task_defined?('test:units:prepare')
      # Redmineのテストタスクが存在しない場合のフォールバック
      puts "Preparing test environment..."
    end
  end
end

# プラグイン固有のテストタスク
namespace :subtask_template do
  desc 'Run subtask_template plugin tests only'
  task :test => ['test:units', 'test:functionals', 'test:integration']
  
  desc 'Run unit tests with coverage'
  task :test_with_coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['test:units'].invoke
  end
end
