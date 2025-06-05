# Subtask Template Plugin Tests

このディレクトリにはSubtask Template Pluginの包括的なテストスイートが含まれています。

## テスト構成

### Unit Tests (`test/unit/`)
- **subtask_template_test.rb**: SubtaskTemplateモデルのテスト
  - バリデーション（名前の必須チェック、長さ制限、一意性）
  - スコープ（global、for_project）
  - 関連モデル（project、subtask_template_items）
  - サブタスク自動作成機能

- **subtask_template_item_test.rb**: SubtaskTemplateItemモデルのテスト
  - バリデーション（タイトル必須、長さ制限）
  - 関連モデル（template、assigned_to、tracker、priority）
  - 順序付け（ordered scope）

### Functional Tests (`test/functional/`)
- **subtask_templates_controller_test.rb**: コントローラーのテスト
  - CRUD操作（作成、読み込み、更新、削除）
  - ネストした属性の処理
  - 認証・認可（管理者権限チェック）
  - バリデーションエラーハンドリング

### Integration Tests (`test/integration/`)
- **subtask_templates_integration_test.rb**: 統合テスト
  - 完全なワークフローテスト
  - ブラウザ操作のシミュレーション
  - アクセス制御の確認
  - エンドツーエンドの機能テスト

## テスト実行方法

### 1. 自動テストスクリプト使用（推奨）
```bash
chmod +x test_runner.sh
./test_runner.sh
```

### 2. 手動実行
```bash
# Docker環境でRedmineコンテナにアクセス
docker-compose exec redmine bash

# テスト環境準備
cd /usr/src/redmine
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate  
RAILS_ENV=test bundle exec rake redmine:plugins:migrate

# 全テスト実行
RAILS_ENV=test bundle exec rake test TEST=plugins/subtask_template/test/**/*_test.rb

# 個別テスト実行
RAILS_ENV=test bundle exec ruby plugins/subtask_template/test/unit/subtask_template_test.rb
RAILS_ENV=test bundle exec ruby plugins/subtask_template/test/functional/subtask_templates_controller_test.rb
RAILS_ENV=test bundle exec ruby plugins/subtask_template/test/integration/subtask_templates_integration_test.rb
```

### 3. カテゴリ別実行
```bash
# ユニットテストのみ
RAILS_ENV=test bundle exec rake test:units TEST=plugins/subtask_template/test/unit/**/*_test.rb

# 機能テストのみ  
RAILS_ENV=test bundle exec rake test:functionals TEST=plugins/subtask_template/test/functional/**/*_test.rb

# 統合テストのみ
RAILS_ENV=test bundle exec rake test:integration TEST=plugins/subtask_template/test/integration/**/*_test.rb
```

## テストデータ

### Fixtures (`test/fixtures/`)
- `subtask_templates.yml`: テンプレートのテストデータ
- `subtask_template_items.yml`: サブタスクアイテムのテストデータ

### Test Helper (`test/test_helper.rb`)
テスト用の共通ヘルパーメソッド:
- `create_test_project`: テスト用プロジェクト作成
- `create_test_user`: テスト用ユーザー作成  
- `create_test_template`: テスト用テンプレート作成
- `create_test_template_item`: テスト用サブタスクアイテム作成
- `ensure_default_data`: Redmineデフォルトデータの確保

## テストカバレッジ

### モデルテスト
- ✅ バリデーション（必須項目、長さ制限、一意性）
- ✅ 関連モデル（belongs_to、has_many）
- ✅ スコープ（global、for_project、ordered）
- ✅ ビジネスロジック（サブタスク作成、表示名生成）
- ✅ ネストした属性（accepts_nested_attributes_for）

### コントローラーテスト  
- ✅ 全CRUD操作（index、show、new、create、edit、update、destroy）
- ✅ 認証・認可（require_admin、ログイン必須）
- ✅ パラメータ処理（strong parameters）
- ✅ エラーハンドリング（バリデーション失敗）
- ✅ フラッシュメッセージ
- ✅ リダイレクト

### 統合テスト
- ✅ 完全なワークフロー（作成→表示→編集→削除）
- ✅ サブタスク自動作成機能
- ✅ アクセス制御（管理者以外のアクセス拒否）
- ✅ フォーム操作（動的フィールド追加・削除）
- ✅ エラー処理（無効データ送信）

## 継続的インテグレーション

### GitHubActions設定例
```yaml
name: Plugin Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: |
          docker-compose up -d
          sleep 30
          ./test_runner.sh
```

## トラブルシューティング

### よくある問題

1. **データベース接続エラー**
   ```bash
   # PostgreSQLコンテナが起動していることを確認
   docker-compose ps
   ```

2. **Redmineが起動しない**
   ```bash  
   # ログを確認
   docker-compose logs redmine
   ```

3. **テストが見つからない**
   ```bash
   # テストファイルのパスを確認
   find plugins/subtask_template/test -name "*_test.rb"
   ```

4. **フィクスチャエラー**
   ```bash
   # Redmineのデフォルトフィクスチャを読み込み
   RAILS_ENV=test bundle exec rake db:fixtures:load
   ```

## ベストプラクティス

1. **テスト分離**: 各テストが独立して実行できることを確保
2. **データクリーンアップ**: テスト後のデータは自動的にロールバック
3. **リアルなシナリオ**: 実際のユーザー操作を模倣したテストケース
4. **エッジケース**: 境界値やエラー条件のテスト
5. **パフォーマンス**: 大量データでの動作確認
