# プラグイン専用のテストヘルパー（mocha非依存版）
ENV['RAILS_ENV'] = 'test'

# 既にRailsが読み込まれているかチェック
unless defined?(Rails)
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
    # ファイルの場所から推測
    redmine_root = File.expand_path('../../../../', __FILE__)
  end

  # Railsアプリケーションを読み込み
  require File.join(redmine_root, 'config', 'environment.rb')
end

require 'rails/test_help' unless defined?(Rails::TestCase)
require 'minitest/autorun' unless defined?(Minitest::Test)

# ActiveSupportのテストケースを拡張
class ActiveSupport::TestCase
  # トランザクションでテストをラップ
  self.use_transactional_tests = true

  # フィクスチャの設定
  self.fixture_path = Rails.root.join('test/fixtures')

  # 基本的なフィクスチャを読み込み
  fixtures :projects, :users, :trackers, :issue_statuses, :issues,
           :enumerations, :roles, :members, :member_roles,
           :enabled_modules

  # テスト用ユーザーの作成
  def setup_test_user(role = 'admin')
    @user = User.find_by_login('admin') || User.first
    User.current = @user
  end

  # テスト用プロジェクトの作成
  def setup_test_project
    @project = Project.find(1) || Project.create!(
      name: 'Test Project',
      identifier: 'test-project',
      description: 'Test project for subtask template'
    )
  end

  # テスト用トラッカーの取得
  def default_tracker
    Tracker.first || Tracker.create!(
      name: 'Bug',
      description: 'Bug tracker',
      issue_statuses: IssueStatus.all,
      projects: Project.all
    )
  end

  # テスト用優先度の取得
  def default_priority
    IssuePriority.default || IssuePriority.first || IssuePriority.create!(
      name: 'Normal',
      position: 1,
      is_default: true
    )
  end

  # テスト用ステータスの取得
  def default_status
    IssueStatus.first || IssueStatus.create!(
      name: 'New',
      position: 1,
      is_default: true
    )
  end
end

# コントローラーテスト用のベースクラス
class ActionController::TestCase
  # セットアップ
  def setup
    @request = ActionController::TestRequest.create
    @response = ActionController::TestResponse.new
    super
  end
end

# 統合テスト用のベースクラス
class ActionDispatch::IntegrationTest
  # フィクスチャの設定
  fixtures :projects, :users, :trackers, :issue_statuses, :issues,
           :enumerations, :roles, :members, :member_roles,
           :enabled_modules

  # ユーザーログイン用ヘルパー（簡略版）
  def log_user(login, password)
    user = User.find_by_login(login)
    if user
      User.current = user
      # 簡易的なセッション設定
      post '/login', params: { username: login, password: password }
    end
  rescue
    # ログイン処理でエラーが発生した場合は、User.currentで直接設定
    user = User.find_by_login(login)
    User.current = user if user
  end
end

puts "Plugin test helper loaded successfully (mocha-free version)." unless $test_helper_loaded
$test_helper_loaded = true
