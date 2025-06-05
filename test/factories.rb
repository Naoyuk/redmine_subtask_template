# テスト用のファクトリー定義
FactoryBot.define do
  # SubtaskTemplateのファクトリー
  factory :subtask_template do
    sequence(:name) { |n| "Test Template #{n}" }
    description { "Test template description" }
    project { nil } # グローバルテンプレート
    
    trait :with_project do
      association :project
    end
    
    trait :with_subtask_items do
      after(:create) do |template|
        create_list(:subtask_template_item, 2, subtask_template: template)
      end
    end
  end
  
  # SubtaskTemplateItemのファクトリー
  factory :subtask_template_item do
    association :subtask_template
    sequence(:title) { |n| "Subtask #{n}" }
    description { "Test subtask description" }
    assigned_to { nil }
    priority { nil }
    tracker { nil }
  end
  
  # Projectのファクトリー（既存のものがない場合用）
  factory :project do
    sequence(:name) { |n| "Test Project #{n}" }
    sequence(:identifier) { |n| "test-project-#{n}" }
    description { "Test project description" }
    status { Project::STATUS_ACTIVE }
  end
  
  # Userのファクトリー（既存のものがない場合用）
  factory :user do
    sequence(:login) { |n| "user#{n}" }
    sequence(:firstname) { |n| "First#{n}" }
    sequence(:lastname) { |n| "Last#{n}" }
    sequence(:mail) { |n| "user#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    status { User::STATUS_ACTIVE }
  end
  
  # Trackerのファクトリー（既存のものがない場合用）
  factory :tracker do
    sequence(:name) { |n| "Tracker #{n}" }
    default_status { IssueStatus.first || association(:issue_status) }
    core_fields { Tracker::CORE_FIELDS }
  end
  
  # IssuePriorityのファクトリー（既存のものがない場合用）
  factory :issue_priority do
    sequence(:name) { |n| "Priority #{n}" }
    sequence(:position) { |n| n }
  end
  
  # IssueStatusのファクトリー（既存のものがない場合用）
  factory :issue_status do
    sequence(:name) { |n| "Status #{n}" }
    sequence(:position) { |n| n }
  end
end
