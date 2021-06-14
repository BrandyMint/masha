# Маша учетчица

[![Build Status](https://travis-ci.org/BrandyMint/masha.svg?branch=master)](https://travis-ci.org/BrandyMint/masha)

## Установка

1. Используйте менеджеро версий ruby, например rbenv - https://github.com/rbenv/rbenv
2. создай ключи для oauth на `github`
3.* пропиши их в <tt>./config/omniauth.yml</tt> по примеру <tt>./config/omniauth.yml.example</tt>

## При деплое на сервере выполнить

> rake telegram:bot:set_webhook RAILS_ENV=production CERT=path/to/cert

## Разработка

> rake telegram:bot:poller 
> rails s

Разработческий бот @MashDevBot

## Распределение прав доступа

Для каждого проекта у пользователя устанавливается его роль в проекте (владелец, смотритель, участник)

<table>
<tr>
<th>Роль</th>
<th>Отмечать, смотреть и изменять свое время</th>
<th>Смотреть чужое время</th>
<th>Возможность приглашать других участников и устанавливать роли</th>
<th>Возможность добавлять, изменять и удалять чужое время</th></tr>
<tr><td>Владелец</td><td>&#10004;</td><td>&#10004;</td><td>&#10004;</td><td>&#10004;</td></tr>
<tr><td>Смотритель</td><td>&#10004;</td><td>&#10004;</td><td>&middot;</td><td>&middot;</td></tr>
<tr><td>Участник</td><td>&#10004;</td><td>&middot;</td><td>&middot;</td><td>&middot;</td></tr>
</table>

## Active admin in development

Логин: admin@example.com
Пароль: password
