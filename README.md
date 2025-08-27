# Маша-учетчицa

Сервис для учета потраченного на работу время в виде телеграм бота https://t.me/MashTimeBot и веб-сервиса https://mashtime.ru

[![Tests](https://github.com/BrandyMint/masha/actions/workflows/tests.yml/badge.svg)](https://github.com/BrandyMint/masha/actions/workflows/tests.yml)

## Зависимости:

* rbenv
* docker compose

## Установка

1. docker compose up
2. создай ключи для oauth на `github`

## При деплое на сервере выполнить

> rake telegram:bot:set_webhook RAILS_ENV=production 

## Разработка

> rake telegram:bot:poller 
> rails s

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
