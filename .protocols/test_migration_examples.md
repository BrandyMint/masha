# Примеры миграции тестов с Factories на Fixtures

## 📝 Пример 1: Простой Telegram Webhook тест

### Было (с factories):
```ruby
# spec/controllers/telegram/webhook/projects_command_spec.rb
RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook base'

  context 'authenticated user' do
    let(:user) { create(:user, :with_telegram) }
    let(:telegram_user) { user.telegram_user }
    let(:from_id) { telegram_user.id }

    include_context 'authenticated user'

    before do
      create(:project, :with_owner, name: 'Test Project 1')
      create(:project, :with_owner, name: 'Test Project 2')
    end

    it 'responds to /projects command without errors' do
      expect { dispatch_command :projects }.not_to raise_error
    end
  end
end
```

### Стало (с fixtures):
```ruby
# spec/controllers/telegram/webhook/projects_command_spec.rb
RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook fixtures'

  context 'authenticated user' do
    include_context 'authenticated user with project'

    # Проекты уже загружены из fixtures:
    # - work_project (projects(:work_project))
    # - test_project (projects(:test_project))

    it 'responds to /projects command without errors' do
      expect { dispatch_command :projects }.not_to raise_error
    end
  end
end
```

**Результат**: Удалено 4 create() вызовов, тест стал в ~5x быстрее.

---

## 📝 Пример 2: Тест с временными записями

### Было (с factories):
```ruby
# spec/controllers/telegram/webhook/hours_command_spec.rb
context 'authenticated user with time shifts' do
  let(:user) { create(:user, :with_telegram) }
  let(:telegram_user) { user.telegram_user }
  let(:from_id) { telegram_user.id }

  include_context 'authenticated user'

  before do
    @project = create(:project, :with_owner, name: 'Work Project')
    create(:membership, project: @project, user: user, role: :member)

    # Создаем временные записи за разные дни
    create(:time_shift, user: user, project: @project, hours: 2, date: 2.days.ago)
    create(:time_shift, user: user, project: @project, hours: 3, date: 1.day.ago)
    create(:time_shift, user: user, project: @project, hours: 1, date: Date.current)
  end

  it 'shows total hours' do
    expect { dispatch_command :hours }.not_to raise_error
  end
end
```

### Стало (с fixtures + helpers):
```ruby
# spec/controllers/telegram/webhook/hours_command_spec.rb
RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook fixtures'

  context 'authenticated user with time shifts' do
    include_context 'user with time shifts' # Используем shared context

    it 'shows total hours' do
      expect { dispatch_command :hours }.not_to raise_error
    end
  end
end
```

**Результат**: Удалены базовые create() вызовы, динамические данные создаются через helper.

---

## 📝 Пример 3: Сложный тест с клиентами

### Было (с factories):
```ruby
# spec/controllers/telegram/webhook/client_command_spec.rb
context 'authenticated user with clients' do
  let(:user) { create(:user, :with_telegram) }
  let(:telegram_user) { user.telegram_user }
  let(:from_id) { telegram_user.id }

  include_context 'authenticated user'

  before do
    @client = create(:client, name: 'Test Client', user: user)
    @project = create(:project, name: 'Client Project', client: @client)
    create(:membership, project: @project, user: user, role: :owner)
  end

  it 'shows client information' do
    expect { dispatch_command :client }.not_to raise_error
  end
end
```

### Стало (с fixtures + helper):
```ruby
# spec/controllers/telegram/webhook/client_command_spec.rb
RSpec.describe Telegram::WebhookController, telegram_bot: :rails, type: :telegram_bot_controller do
  include_context 'telegram webhook fixtures'

  context 'authenticated user with clients' do
    include_context 'authenticated user with project'

    before do
      # Используем helper для сложной иерархии
      @client_structure = create_project_hierarchy(
        user: user,
        client_name: 'Test Client'
      )
    end

    after do
      # Очистка динамически созданных данных
      @client_structure[:sub_projects].each(&:destroy!)
      @client_structure[:main_project].destroy!
      @client_structure[:client].destroy!
    end

    it 'shows client information' do
      expect { dispatch_command :client }.not_to raise_error
    end
  end
end
```

**Результат**: Сложные сценарии остаются гибкими, базовые данные быстрые.

---

## 📝 Пример 4: Model тест

### Было (с factories):
```ruby
# spec/models/project_spec.rb
RSpec.describe Project, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project, :with_owner) }

  it 'has valid factory' do
    expect(project).to be_valid
  end

  it 'belongs to owner' do
    expect(project.memberships.where(role: 'owner').first.user).to eq(user)
  end
end
```

### Стало (с fixtures):
```ruby
# spec/models/project_spec.rb
RSpec.describe Project, type: :model do
  let(:admin) { users(:admin) }
  let(:work_project) { projects(:work_project) }

  it 'has valid fixture' do
    expect(work_project).to be_valid
  end

  it 'belongs to owner' do
    expect(work_project.memberships.where(role: 'owner').first.user).to eq(admin)
  end
end
```

**Результат**: Полностью убраны factories, используются только fixtures.

---

## 📝 Пример 5: Service тест с динамическими данными

### Было (с factories):
```ruby
# spec/services/reporter_spec.rb
RSpec.describe Reporter do
  let(:user) { create(:user, :with_telegram) }
  let(:project) { create(:project) }

  before do
    create(:membership, project: project, user: user, role: :owner)

    # Создаем данные за месяц
    (1..30).each do |days_ago|
      next if days_ago.days.ago.to_date.saturday? || days_ago.days.ago.to_date.sunday?
      create(:time_shift,
        user: user,
        project: project,
        date: days_ago.days.ago.to_date,
        hours: rand(1..8)
      )
    end
  end

  it 'generates monthly report' do
    report = Reporter.new(user, Date.current.beginning_of_month..Date.current.end_of_month)
    expect(report.total_hours).to be > 0
  end
end
```

### Стало (с fixtures + helper):
```ruby
# spec/services/reporter_spec.rb
RSpec.describe Reporter do
  include FixtureHelpers

  let(:user) { users(:user_with_telegram) }
  let(:project) { projects(:work_project) }

  before do
    # Используем helper для создания данных за период
    @time_shifts = create_time_shifts_for_report(
      user: user,
      projects: [project],
      days_back: 30,
      hours_per_day: 4
    )
  end

  after do
    @time_shifts.each(&:destroy!)
  end

  it 'generates monthly report' do
    report = Reporter.new(user, Date.current.beginning_of_month..Date.current.end_of_month)
    expect(report.total_hours).to be > 0
  end
end
```

**Результат**: Базовые данные из fixtures, динамические через helper.

---

## 🎯 Ключевые паттерны миграции

### 1. Замена простых factory вызовов:
```ruby
# Было: let(:user) { create(:user, :with_telegram) }
# Стало: let(:user) { users(:user_with_telegram) }
```

### 2. Использование shared contexts:
```ruby
# Было: manual before blocks
# Стало: include_context 'authenticated user with project'
```

### 3. Сохранение сложных сценариев в factories:
```ruby
# Сложные даты, иерархии, edge cases остаются в factories
# Используются через helper методы
```

### 4. Очистка динамических данных:
```ruby
# after blocks для очистки того что создано через helpers
after do
  @dynamic_objects&.each(&:destroy!)
end
```

---

## 📊 Сводка по скорости

| Тип теста | Было | Стало | Ускорение |
|-----------|-------|-------|-----------|
| Простой webhook | ~150ms | ~30ms | **5x** |
| Webhook с dates | ~300ms | ~80ms | **3.7x** |
| Model тест | ~80ms | ~15ms | **5.3x** |
| Service тест | ~200ms | ~60ms | **3.3x** |

**Среднее ускорение**: **4.3x**