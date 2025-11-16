# План реализации: Веб-справка (Вариант 1)

**Статус**: В процессе
**Версия**: 1.0
**Дата**: 2025-11-16

---

## 1. Обзор

Пошаговый план реализации веб-справки используя Rails контроллер + HAML views.

---

## 2. Список файлов для создания/изменения

### Новые файлы
```
app/controllers/help_controller.rb          # Контроллер
app/views/help/
  ├─ _nav.html.haml                        # Навигация (partial)
  ├─ index.html.haml                       # Главная
  ├─ guide.html.haml                       # Полный гайд
  ├─ quick_start.html.haml                 # Быстрый старт
  ├─ commands.html.haml                    # Справка по командам
  ├─ time_format.html.haml                 # Форматы времени
  ├─ projects.html.haml                    # Управление проектами
  └─ faq.html.haml                         # FAQ
app/views/layouts/help.html.haml           # Layout для справки (опционально)
```

### Изменяемые файлы
```
config/routes.rb                            # Добавить маршруты
config/locales/ru.yml                       # Добавить i18n тексты
```

---

## 3. Этап 1: Контроллер

### Файл: `app/controllers/help_controller.rb`

```ruby
# frozen_string_literal: true

class HelpController < ApplicationController
  skip_authentication # Справка доступна всем

  def index; end

  def guide; end

  def quick_start; end

  def commands; end

  def time_format; end

  def projects; end

  def faq; end
end
```

**Ключевые моменты**:
- `skip_authentication` - справка доступна без логина
- Простые методы - логика в views

---

## 4. Этап 2: Маршруты

### Файл: `config/routes.rb` (добавить в конец)

```ruby
namespace :help do
  root 'help#index'
  get 'guide', action: :guide, as: :guide
  get 'quick-start', action: :quick_start, as: :quick_start
  get 'commands', action: :commands, as: :commands
  get 'time-format', action: :time_format, as: :time_format
  get 'projects', action: :projects, as: :projects
  get 'faq', action: :faq, as: :faq
end

# или проще через legacy routing:
get 'help', to: 'help#index'
get 'help/guide', to: 'help#guide'
get 'help/quick-start', to: 'help#quick_start'
get 'help/commands', to: 'help#commands'
get 'help/time-format', to: 'help#time_format'
get 'help/projects', to: 'help#projects'
get 'help/faq', to: 'help#faq'
```

**Примечание**: Используем наиболее подходящий стиль. Проверим существующие маршруты в routes.rb.

---

## 5. Этап 3: HAML Views

### 5.1 Partial навигации: `app/views/help/_nav.html.haml`

```haml
.help-navigation
  %nav.navbar.navbar-expand-sm.navbar-light.bg-light
    .container
      %button.navbar-toggler{"aria-controls" => "navbarNav", "aria-expanded" => "false", "aria-label" => "Toggle navigation", "data-bs-target" => "#navbarNav", "data-bs-toggle" => "collapse", :type => "button"}
        %span.navbar-toggler-icon
      #navbarNav.collapse.navbar-collapse
        %ul.navbar-nav.ms-auto
          %li.nav-item
            = link_to t('help.nav.index'), help_path, class: "nav-link #{active_page?(:index)}"
          %li.nav-item
            = link_to t('help.nav.quick_start'), help_quick_start_path, class: "nav-link #{active_page?(:quick_start)}"
          %li.nav-item
            = link_to t('help.nav.guide'), help_guide_path, class: "nav-link #{active_page?(:guide)}"
          %li.nav-item
            = link_to t('help.nav.commands'), help_commands_path, class: "nav-link #{active_page?(:commands)}"
          %li.nav-item
            = link_to t('help.nav.time_format'), help_time_format_path, class: "nav-link #{active_page?(:time_format)}"
          %li.nav-item
            = link_to t('help.nav.projects'), help_projects_path, class: "nav-link #{active_page?(:projects)}"
          %li.nav-item
            = link_to t('help.nav.faq'), help_faq_path, class: "nav-link #{active_page?(:faq)}"
```

### 5.2 Layout для справки: `app/views/layouts/help.html.haml`

```haml
<!DOCTYPE html>
%html
  %head
    %meta{charset: "utf-8"}
    %meta{name: "viewport", content: "width=device-width, initial-scale=1"}
    %title= "#{@page_title} - Masha"
    = csrf_meta_tags
    = csp_meta_tag
    = stylesheet_link_tag 'application', media: 'all'
  %body
    = render 'help/nav'
    .help-container
      .container.mt-4
        = yield
    = javascript_include_tag 'application'
```

### 5.3 Главная страница: `app/views/help/index.html.haml`

```haml
- @page_title = t('help.index.title')

.row
  .col-md-8
    %h1= t('help.index.title')

    %p= t('help.index.intro')

    %h2= t('help.index.getting_started')
    %ol
      %li
        %strong= t('help.index.step1_title')
        %p= t('help.index.step1_desc')
      %li
        %strong= t('help.index.step2_title')
        %p= t('help.index.step2_desc')
      %li
        %strong= t('help.index.step3_title')
        %p= t('help.index.step3_desc')

    %h2= t('help.index.topics')
    .list-group
      = link_to t('help.nav.quick_start'), help_quick_start_path, class: 'list-group-item list-group-item-action'
      = link_to t('help.nav.guide'), help_guide_path, class: 'list-group-item list-group-item-action'
      = link_to t('help.nav.commands'), help_commands_path, class: 'list-group-item list-group-item-action'
      = link_to t('help.nav.time_format'), help_time_format_path, class: 'list-group-item list-group-item-action'
      = link_to t('help.nav.projects'), help_projects_path, class: 'list-group-item list-group-item-action'
      = link_to t('help.nav.faq'), help_faq_path, class: 'list-group-item list-group-item-action'

  .col-md-4
    %aside.help-sidebar
      .card
        .card-header
          %h5 💡= t('help.sidebar.tip')
        .card-body
          %p= t('help.sidebar.quick_commands')
          %code= '/start'
          %code= '/projects'
          %code= '/add'
          %code= '/report'
```

### 5.4 Быстрый старт: `app/views/help/quick_start.html.haml`

```haml
- @page_title = t('help.quick_start.title')

.row
  .col-md-9
    %h1= t('help.quick_start.title')

    %p.lead= t('help.quick_start.subtitle')

    %h2#what-is-masha= t('help.quick_start.what_is')
    %p= t('help.quick_start.what_is_desc')

    %h2#three-steps= t('help.quick_start.three_steps')

    .step
      %h3
        %span.badge.bg-primary 1
        = t('help.quick_start.step1_title')
      %p= t('help.quick_start.step1_desc')
      %p
        %code /projects create my-project

    .step
      %h3
        %span.badge.bg-primary 2
        = t('help.quick_start.step2_title')
      %p= t('help.quick_start.step2_desc')
      %p
        %code 2 my-project Первая задача

    .step
      %h3
        %span.badge.bg-primary 3
        = t('help.quick_start.step3_title')
      %p= t('help.quick_start.step3_desc')
      %p
        %code /report week

    %h2#common-mistakes= t('help.quick_start.common_mistakes')
    .alert.alert-warning
      %strong= t('help.quick_start.mistake1_title')
      %p= t('help.quick_start.mistake1_desc')

    %h2#next-steps= t('help.quick_start.next_steps')
    %ul
      %li= link_to t('help.nav.guide'), help_guide_path
      %li= link_to t('help.nav.commands'), help_commands_path
      %li= link_to t('help.nav.faq'), help_faq_path
```

### 5.5 Полный гайд: `app/views/help/guide.html.haml`

```haml
- @page_title = t('help.guide.title')

%h1= t('help.guide.title')

%p.lead= t('help.guide.subtitle')

.toc
  %h2= t('help.guide.table_of_contents')
  %ul
    %li= link_to t('help.guide.concepts'), '#concepts'
    %li= link_to t('help.guide.getting_started'), '#getting-started'
    %li= link_to t('help.guide.tracking_time'), '#tracking-time'
    %li= link_to t('help.guide.reports'), '#reports'
    %li= link_to t('help.guide.projects'), '#projects'

%h2#concepts= t('help.guide.concepts')

%h3= t('help.guide.project')
%p= t('help.guide.project_desc')

%h3= t('help.guide.time_entry')
%p= t('help.guide.time_entry_desc')

%h3= t('help.guide.roles')
%p= t('help.guide.roles_desc')
%ul
  %li
    %strong Owner:
    = t('help.guide.role_owner')
  %li
    %strong Watcher:
    = t('help.guide.role_watcher')
  %li
    %strong Participant:
    = t('help.guide.role_participant')

%h2#getting-started= t('help.guide.getting_started')
%p= link_to t('help.nav.quick_start'), help_quick_start_path

%h2#tracking-time= t('help.guide.tracking_time')
%p= link_to t('help.nav.time_format'), help_time_format_path

%h2#reports= t('help.guide.reports')
%p= t('help.guide.reports_desc')
%p
  %code /report week
  %code /report month
  %code /report today

%h2#projects= t('help.guide.projects')
%p= link_to t('help.nav.projects'), help_projects_path
```

### 5.6 Форматы времени: `app/views/help/time_format.html.haml`

```haml
- @page_title = t('help.time_format.title')

%h1= t('help.time_format.title')

%h2= t('help.time_format.basic_format')
%p= t('help.time_format.basic_format_desc')

.code-example
  %pre
    %code
      2 my-project Работа над задачей
  %p
    %small Добавляет 2 часа в проект "my-project" с описанием "Работа над задачей"

%h2= t('help.time_format.decimal_hours')
%p= t('help.time_format.decimal_hours_desc')

.code-example
  %pre
    %code
      1.5 design Правка дизайна
  %p
    %small Добавляет 1.5 часа

%h2= t('help.time_format.time_first')
%p= t('help.time_format.time_first_desc')

.code-example
  %pre
    %code
      /add 2 my-project Описание
  %p
    %small Команда с явным указанием часов

%h2= t('help.time_format.validation')
%p= t('help.time_format.validation_desc')
%ul
  %li t('help.time_format.min_hours')
  %li t('help.time_format.max_description')
  %li t('help.time_format.project_required')
```

### 5.7 Команды: `app/views/help/commands.html.haml`

```haml
- @page_title = t('help.commands.title')

%h1= t('help.commands.title')

%h2= t('help.commands.basic')

.command
  %h3
    %code /start
  %p= t('help.commands.start_desc')

.command
  %h3
    %code /add
  %p= t('help.commands.add_desc')

.command
  %h3
    %code /report
  %p= t('help.commands.report_desc')

.command
  %h3
    %code /projects
  %p= t('help.commands.projects_desc')

.command
  %h3
    %code /clients
  %p= t('help.commands.clients_desc')

%h2= t('help.commands.admin')

.command
  %h3
    %code /notify
  %p= t('help.commands.notify_desc')
```

### 5.8 Управление проектами: `app/views/help/projects.html.haml`

```haml
- @page_title = t('help.projects.title')

%h1= t('help.projects.title')

%h2= t('help.projects.create')
%p= t('help.projects.create_desc')

.code-example
  %pre
    %code
      /projects create my-project

%h2= t('help.projects.view')
%p= t('help.projects.view_desc')

.code-example
  %pre
    %code
      /projects

%h2= t('help.projects.add_user')
%p= t('help.projects.add_user_desc')
```

### 5.9 FAQ: `app/views/help/faq.html.haml`

```haml
- @page_title = t('help.faq.title')

%h1= t('help.faq.title')

.accordion
  .accordion-item
    %h2.accordion-header
      %button.accordion-button{"aria-controls" => "faq1", "aria-expanded" => "false", "data-bs-target" => "#faq1", "data-bs-toggle" => "collapse", :type => "button"}
        = t('help.faq.q1')
    #faq1.accordion-collapse.collapse{"aria-labelledby" => "headingOne", "data-bs-parent" => ".accordion"}
      .accordion-body
        = t('help.faq.a1')

  .accordion-item
    %h2.accordion-header
      %button.accordion-button.collapsed{"aria-controls" => "faq2", "aria-expanded" => "false", "data-bs-target" => "#faq2", "data-bs-toggle" => "collapse", :type => "button"}
        = t('help.faq.q2')
    #faq2.accordion-collapse.collapse{"aria-labelledby" => "headingTwo", "data-bs-parent" => ".accordion"}
      .accordion-body
        = t('help.faq.a2')

  .accordion-item
    %h2.accordion-header
      %button.accordion-button.collapsed{"aria-controls" => "faq3", "aria-expanded" => "false", "data-bs-target" => "#faq3", "data-bs-toggle" => "collapse", :type => "button"}
        = t('help.faq.q3')
    #faq3.accordion-collapse.collapse{"aria-labelledby" => "headingThree", "data-bs-parent" => ".accordion"}
      .accordion-body
        = t('help.faq.a3')
```

---

## 6. Этап 4: i18n Локализация

### Файл: `config/locales/ru.yml` (добавить в конец)

```yaml
ru:
  help:
    nav:
      index: 'Справка'
      quick_start: 'Быстрый старт'
      guide: 'Полный гайд'
      commands: 'Команды'
      time_format: 'Форматы времени'
      projects: 'Проекты'
      faq: 'Часто спрашивают'

    sidebar:
      tip: 'Совет'
      quick_commands: 'Основные команды:'

    index:
      title: 'Справка по Masha'
      intro: 'Masha — это бот для отслеживания времени, которое вы тратите на разные задачи.'
      getting_started: 'С чего начать?'
      step1_title: 'Создайте проект'
      step1_desc: 'Проект — это категория для отслеживания времени.'
      step2_title: 'Добавьте время'
      step2_desc: 'Отмечайте время, которое вы тратите на задачи.'
      step3_title: 'Смотрите отчеты'
      step3_desc: 'Анализируйте, сколько времени вы потратили.'
      topics: 'Разделы справки'

    quick_start:
      title: 'Быстрый старт'
      subtitle: 'Начните отслеживать время за 3 минуты'
      what_is: 'Что такое Masha?'
      what_is_desc: 'Masha — это Telegram бот, который помогает отслеживать, сколько времени вы тратите на разные задачи. Создавайте проекты, добавляйте записи времени и смотрите детальные отчеты.'
      three_steps: 'Три шага для начала'
      step1_title: 'Создать проект'
      step1_desc: 'Проект — это категория для группировки записей времени. Используйте команду /projects create или нажмите кнопку на приветствии.'
      step2_title: 'Добавить время'
      step2_desc: 'Отправьте сообщение в формате "2 my-project Описание", где 2 — часы.'
      step3_title: 'Посмотреть отчет'
      step3_desc: 'Используйте команду /report week для просмотра отчета за неделю.'
      common_mistakes: 'Частые ошибки'
      mistake1_title: 'Проект не найден'
      mistake1_desc: 'Убедитесь, что вы используете правильный slug проекта (идентификатор), который вы указали при создании.'
      next_steps: 'Что дальше?'

    guide:
      title: 'Полное руководство'
      subtitle: 'Все, что нужно знать о Masha'
      table_of_contents: 'Содержание'
      concepts: 'Основные понятия'
      getting_started: 'С чего начать'
      tracking_time: 'Отслеживание времени'
      reports: 'Отчеты'
      projects: 'Проекты'
      project: 'Проект'
      project_desc: 'Проект — это категория для группировки записей времени. Например: "work-project", "personal", "client-acme".'
      time_entry: 'Запись времени'
      time_entry_desc: 'Запись времени содержит количество часов, проект и описание выполненной задачи.'
      roles: 'Роли в проекте'
      roles_desc: 'Каждый проект может иметь разные роли доступа:'
      role_owner: 'Владелец — может управлять пользователями, удалять проект'
      role_watcher: 'Наблюдатель — может видеть все записи в проекте'
      role_participant: 'Участник — может видеть только свои записи'
      tracking_time: 'Отслеживание времени'
      reports_desc: 'Используйте команду /report для просмотра сводки потраченного времени.'

    time_format:
      title: 'Форматы добавления времени'
      basic_format: 'Базовый формат'
      basic_format_desc: 'Отправьте сообщение с часами, slug проекта и описанием:'
      decimal_hours: 'Дробные часы'
      decimal_hours_desc: 'Поддерживаются дробные часы (1.5, 2.25, 0.5 и т.д.)'
      time_first: 'Формат с явной командой'
      time_first_desc: 'Используйте команду /add с параметрами:'
      validation: 'Валидация'
      validation_desc: 'Требования к формату:'
      min_hours: 'Минимум 0.25 часа'
      max_description: 'Максимум 250 символов в описании'
      project_required: 'Проект должен существовать'

    commands:
      title: 'Справка по командам'
      basic: 'Основные команды'
      start_desc: 'Приветствие и помощь при первом запуске'
      add_desc: 'Добавить запись времени'
      report_desc: 'Просмотреть отчет по времени'
      projects_desc: 'Управление проектами'
      clients_desc: 'Управление клиентами (компаниями)'
      admin: 'Команды администратора'
      notify_desc: 'Отправить массовое уведомление всем пользователям (только для разработчика)'

    projects:
      title: 'Управление проектами'
      create: 'Создание проекта'
      create_desc: 'Используйте команду /projects create, чтобы создать новый проект:'
      view: 'Просмотр проектов'
      view_desc: 'Команда /projects показывает все ваши проекты'
      add_user: 'Добавление пользователя'
      add_user_desc: 'В проекте можно приглашать других пользователей'

    faq:
      title: 'Часто задаваемые вопросы'
      q1: 'Как создать первый проект?'
      a1: 'Используйте команду /projects create, укажите slug (идентификатор) проекта. Например: /projects create my-project'
      q2: 'В каком формате добавлять время?'
      a2: 'Отправьте сообщение: "2 my-project Описание задачи", где 2 — часы, my-project — slug проекта, остальное — описание.'
      q3: 'Могу ли я поделиться проектом с другими?'
      a3: 'Да, используйте команду /projects invite, чтобы пригласить других пользователей в ваш проект.'
```

---

## 7. Проверка маршрутов

Перед реализацией убедитесь в текущей структуре `config/routes.rb`:

```bash
grep -n "PagesController\|pages_controller" config/routes.rb
```

Если используется другой паттерн — подстроим маршруты соответственно.

---

## 8. Порядок реализации

1. ✅ Создать контроллер `app/controllers/help_controller.rb`
2. ✅ Добавить маршруты в `config/routes.rb`
3. ✅ Создать директорию `app/views/help/`
4. ✅ Создать partial `_nav.html.haml`
5. ✅ Создать 7 HAML views (index, guide, quick_start, commands, time_format, projects, faq)
6. ✅ Добавить i18n тексты в `config/locales/ru.yml`
7. ✅ Протестировать все страницы

---

## 9. Тестирование

После реализации проверить:
- [ ] `/help` загружается и показывает главную
- [ ] `/help/guide` загружается
- [ ] `/help/quick-start` загружается
- [ ] `/help/commands` загружается
- [ ] `/help/time-format` загружается
- [ ] `/help/projects` загружается
- [ ] `/help/faq` загружается
- [ ] Навигация работает между страницами
- [ ] i18n тексты отображаются корректно

---

## 10. Следующие шаги

1. Реализовать план выше
2. Добавить интеграцию с Telegram ботом (кнопки со ссылками на справку)
3. Добавить кнопку "Помощь" на каждый главный экран

---

**Статус**: ✅ План готов к реализации
