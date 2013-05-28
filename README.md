Что за шаблон?
===

Это болванка приложения на Rails 4.0, которую удобно брать за основу для
создания новых проектов.

Отличается от `rails new` тем что:

* База уже postgres (с `pg_array_parser`)
* `Twitter Bootstrap`, с правильными лайаутами.
* `simple_form`, `simple_navigation` и `kaminari` с настроенной
  поддержкой `twitter bootstrap`
* Полный комплект `pry` и прочих плюшек, вроде `better_errors` для `development`
* Настроенный `rspec`, `capybara` и `guard`
* Настроен `simple_cov`
* `mailcatcher`, `recipient_interceptor`, `foreman` и прочие типичные гемы в `Gemfile`

Пример
===

    $ \curl -L https://raw.github.com/BrandyMint/rails4_template/master/bootstrap.sh | bash -s Masha

а если у нас уже есть пустой репозиторий на github, то

    $ \curl -L https://raw.github.com/BrandyMint/rails4_template/master/bootstrap.sh | bash -s Masha --git git@github.com:BrandyMint/masha.git


Что при этои происходится?

1. Клонируется проект `rails4_template` в каталог производный от
указанного имени.
2. Рельсовое приложение переименуется в указанное имя
(`Masha::Application`)
3. Базу тоже назовут в ее честь.
4. Запустится `bundle update`
5. Пропишется указанный репозиторий (если указан) и зальется первый
комит.

Что делать дальше?
==================

1. Настроить `./config/application.yml` и `./config/database.yml`
2. Зарегистрировать проект в http://errbit.brandymint.ru/apps и вписать
ключи `./config/initializers/airbrake.rb`

История
=======

layout взяты на основе этого проекта
http://railsapps.github.io/rails-default-application-layout.html
http://railsapps.github.io/twitter-bootstrap-rails.html


Альтернативы
============

* https://github.com/thoughtbot/suspenders
* http://railsapps.github.io/
