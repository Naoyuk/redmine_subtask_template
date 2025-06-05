# Subtask Template Plugin for Redmine

Redmine用のサブタスクテンプレートプラグインです。Issueのテンプレートを管理し、サブタスクを自動的に作成できます。

## 機能

- テンプレートの作成・編集・削除
- サブタスクのタイトル、説明、担当者、優先度の設定
- テンプレートを適用した際の自動サブタスク作成
- プロジェクト別・グローバルテンプレート管理

## 開発環境構築

### 前提条件

- Docker & Docker Compose
- WSL2 (Windows 11)
- Git

### セットアップ手順

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/Naoyuk/redmine_subtask_template subtask_template
   cd subtask_template
   ```

2. **セットアップスクリプトの実行**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

### アクセス情報

- **Redmine URL**: http://localhost:3000
- **デフォルトログイン**: admin / admin
- **PostgreSQL**: localhost:5432

### プラグインの確認

1. ブラウザでRedmineにアクセス
2. 管理者（admin/admin）でログイン
3. **管理** -> **プラグイン**でSubtask Templatesが表示されることを確認
4. **管理** -> **Subtask Templates**で管理画面にアクセス

## テスト実行

### 自動テスト実行
```bash
chmod +x test_runner.rb
ruby test_runner.rb
```

### 手動テスト実行
```bash
# Docker環境でテスト実行
docker-compose exec redmine bash -c "
  cd /usr/src/redmine &&
  RAILS_ENV=test bundle exec rake db:create &&
  RAILS_ENV=test bundle exec rake db:migrate &&
  RAILS_ENV=test bundle exec rake redmine:plugins:migrate &&
  RAILS_ENV=test bundle exec rake test TEST=plugins/subtask_template/test/**/*_test.rb
"
```

### テストカバレッジ
- **Unit Tests**: モデルのバリデーション、関連、ビジネスロジック
- **Functional Tests**: コントローラーのCRUD操作、認証・認可
- **Integration Tests**: エンドツーエンドのワークフロー

## 新規作成画面の使い方

1. 「管理」→「サブタスクテンプレート」→「新規テンプレート」
2. テンプレート名、説明、プロジェクト（オプション）を入力
3. 「サブタスクを追加」ボタンでサブタスク項目を追加
4. 各サブタスクのタイトル、説明、トラッカー、担当者、優先度を設定
5. 「保存」で作成完了
