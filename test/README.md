# Subtask Template Plugin Tests

このディレクトリには、Subtask Template プラグインのテストが含まれています。

## テスト構成

### ディレクトリ構成
```
test/
├── fixtures/                    # テスト用フィクスチャデータ
│   ├── subtask_templates.yml
│   └── subtask_template_items.yml
├── functional/                  # 機能テスト（コントローラーテスト）
│   └── subtask_templates_controller_test.rb
├── integration/                 # 統合テスト
│   └── subtask_template_integration_test.rb
├── unit/                       # ユニットテスト（モデルテスト）
│   ├── subtask_template_test.rb
│   └── subtask_template_item_test.rb
├── test_helper.rb              # テストヘルパー
└── README.md                   # このファイル
```

## テストの実行

### 全体テストの実行
```bash
# Redmineコンテナ内で実行
cd /usr/src/redmine
bundle exec rake subtask_template:test RAILS_ENV=test

# またはホストから実行
docker compose exec redmine bash -c "
  cd /usr/src/redmine &&
  bundle exec rake subtask_template:test RAILS_ENV=test
"
```

### 個別テストの実行

#### ユニットテストのみ
```bash
bundle exec rake subtask_template:test_units RAILS_ENV=test
```

#### 機能テストのみ
```bash
bundle exec rake subtask_template:test_functionals RAILS_ENV=test
```

#### 統合テストのみ
```bash
bundle exec rake subtask_template:test_integration RAILS_ENV=test
```

### テスト環境のセットアップ
```bash
# 初回のみ実行
bundle exec rake subtask_template:setup_test RAILS_ENV=test
```

### 標準のRailsテストランナーでの実行
```bash
# 特定のテストファイルを実行
bundle exec ruby -I"test" plugins/subtask_template/test/unit/subtask_template_test.rb

# 特定のテストメソッドを実行
bundle exec ruby -I"test" plugins/subtask_template/test/unit/subtask_template_test.rb -n test_create_template
```

## テストカバレッジ

SimpleCovがインストールされている場合、テストカバレッジレポートを生成できます：

```bash
# SimpleCovのインストール（必要に応じて）
gem install simplecov

# カバレッジレポートの生成
bundle exec rake subtask_template:coverage RAILS_ENV=test
```

レポートは `plugins/subtask_template/coverage/` ディレクトリに生成されます。

## テスト内容

### ユニットテスト (Models)

#### SubtaskTemplate
- テンプレートの作成、更新、削除
- バリデーション（名前必須、一意性制約など）
- プロジェクトとの関連付け
- グローバルテンプレートとプロジェクト固有テンプレート
- サブタスクアイテムとの関連付け
- サブタスク自動作成機能

#### SubtaskTemplateItem
- サブタスクアイテムの作成、更新、削除
- バリデーション（タイトル必須、文字数制限など）
- テンプレートとの関連付け
- ユーザー、トラッカー、優先度との関連付け
- 位置情報とソート機能

### 機能テスト (Controllers)

#### SubtaskTemplatesController
- 全てのCRUDアクション（index, show, new, create, edit, update, destroy）
- ネストした属性の処理（サブタスクアイテムの作成・更新・削除）
- 権限制御（管理者のみアクセス可能）
- エラーハンドリング
- フラッシュメッセージの表示

### 統合テスト

- 完全なワークフロー（テンプレート作成から削除まで）
- テンプレートからのサブタスク作成
- グローバルテンプレートとプロジェクト固有テンプレートの使い分け
- 権限制御の動作確認
- ネストした属性の処理

## テストデータ

### フィクスチャ
- `subtask_templates.yml`: テスト用テンプレートデータ
- `subtask_template_items.yml`: テスト用サブタスクアイテムデータ

### 前提条件
- Redmineの標準フィクスチャ（projects, users, trackers等）に依存
- テストヘルパーで基本的なセットアップを提供

## トラブルシューティング

### よくある問題

#### テストが実行されない
```bash
# テスト環境が正しくセットアップされているか確認
bundle exec rake subtask_template:setup_test RAILS_ENV=test
```

#### フィクスチャエラー
```bash
# データベースをクリーンにして再セットアップ
bundle exec rake subtask_template:clean_test RAILS_ENV=test
bundle exec rake subtask_template:setup_test RAILS_ENV=test
```

#### 権限エラー
- Redmineの標準フィクスチャが正しく読み込まれているか確認
- テストヘルパーでユーザーが正しく設定されているか確認

## 継続的インテグレーション

GitHubアクションやその他のCIシステムでテストを自動実行する場合：

```yaml
# .github/workflows/test.yml の例
- name: Run plugin tests
  run: |
    docker compose exec redmine bash -c "
      cd /usr/src/redmine &&
      bundle exec rake subtask_template:setup_test RAILS_ENV=test &&
      bundle exec rake subtask_template:test RAILS_ENV=test
    "
```

## テスト追加時の注意点

1. **命名規則**: テストファイルは `*_test.rb` で終わる
2. **継承**: `ActiveSupport::TestCase` または適切な親クラスを継承
3. **フィクスチャ**: 必要に応じてフィクスチャを追加・更新
4. **セットアップ**: `test_helper.rb` の共通メソッドを活用
5. **アサーション**: 明確で理解しやすいアサーションを記述
