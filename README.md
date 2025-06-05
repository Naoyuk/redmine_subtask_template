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
   git clone <repository-url>
   cd subtask_template_plugin
   ```

2. **セットアップスクリプトの実行**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **手動セットアップ（スクリプトが失敗した場合）**
   ```bash
   # プラグインディレクトリの作成
   mkdir -p plugins/subtask_template
   
   # Dockerサービスの起動
   docker compose up -d
   
   # Redmineのセットアップ
   docker compose exec redmine bash -c "
     cd /usr/src/redmine &&
     bundle exec rake generate_secret_token &&
     bundle exec rake db:create RAILS_ENV=production &&
     bundle exec rake db:migrate RAILS_ENV=production &&
     bundle exec rake redmine:load_default_data RAILS_ENV=production REDMINE_LANG=ja
   "
   
   # プラグインのマイグレーション
   docker compose exec redmine bash -c "
     cd /usr/src/redmine &&
     bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   "
   
   # サービスの再起動
   docker compose restart redmine
   ```

### アクセス情報

- **Redmine URL**: http://localhost:3000
- **デフォルトログイン**: admin / admin
- **PostgreSQL**: localhost:5432

### プラグインの確認

1. ブラウザでRedmineにアクセス
2. 管理者（admin/admin）でログイン
3. 「管理」→「プラグイン」でSubtask Template Pluginが表示されることを確認

## ディレクトリ構成

```
plugins/subtask_template/
├── init.rb                                    # プラグイン設定
├── app/
│   ├── controllers/
│   │   └── subtask_templates_controller.rb   # コントローラー
│   ├── models/
│   │   ├── subtask_template.rb               # テンプレートモデル
│   │   └── subtask_template_item.rb          # サブタスクアイテムモデル
│   └── views/
│       └── subtask_templates/
│           └── index.html.erb                # 一覧画面
├── config/
│   └── routes.rb                             # ルーティング
└── db/
    └── migrate/
        └── 001_create_subtask_templates.rb   # マイグレーション
```

## 開発コマンド

```bash
# サービス起動
docker compose up -d

# サービス停止
docker compose down

# ログ確認
docker compose logs redmine

# Redmineコンテナにアクセス
docker compose exec redmine bash

# プラグインマイグレーション
docker compose exec redmine bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# プラグインマイグレーションロールバック  
docker compose exec redmine bundle exec rake redmine:plugins:migrate NAME=subtask_template VERSION=0 RAILS_ENV=production
```

## 次のステップ

1. プラグインが正常に読み込まれることを確認
2. テンプレート作成画面の実装
3. Issue作成時のテンプレート選択機能追加
4. サブタスク自動作成機能の実装
