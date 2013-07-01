= Маша учетчица

Сначала создай ключи для oauth на +github+ и пропиши их в <tt>./config/omniauth.yml</tt> по примеру <tt>./config/omniauth.yml.example</tt>

www :: http://masha.brandymint.ru/
trello :: https://trello.com/board/masha/51af1575c24870a46b0090c8
errbit :: http://errbit.brandymint.ru/apps/51b9cbd7687d9c6efa01e81b

== Распределение прав доступа

Для каждого проекта у пользователя устанавливается собственная проль (владелец, смотритель, участник)

Роль :: Отмечать, смотреть и изменять свое время :: Смотреть чужое время :: Возможность приглашать других участников и устанавливать роли :: Возможность добавлять, изменять и удалять чужое время
Участник :: X :: &middot; :: &middot; :: &middot;
Смотритель :: X :: X :: &middot; :: &middot;
Владелец :: X :: X :: X :: X

== Active admin in development

Логин: admin@example.com
Пароль: password
