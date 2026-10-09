# Makefile templates

В каталоге два базовых framework-варианта:

- `../docker/spiral/Makefile.fragment` — компактный Spiral/RoadRunner-вариант
  с Lua helpers;
- `cakephp-application.Makefile` — CakePHP/multi-service вариант
  lifecycle/release команд.

Оба варианта придерживаются одного публичного контракта: `docker`, `build`,
`up`, `reload-env`, `stop`, `remove`, `ps`, `logs`, `config`, `doctor`,
`release` и `change-release`. Фреймворк-специфичные команды остаются тонкими
обёртками над контейнером приложения.

Перед использованием:

1. Скопируйте выбранный Makefile в новую ветку проекта.
2. Настройте имена сервисов, compose-файлы, env-файлы и команды приложения.
3. Перенесите нужные wrappers из `../docker/spiral/compose`.
4. Добавьте проектные release scripts до включения `release` и
   `change-release` в рабочий процесс.
5. Проверьте `make doctor`, итоговый Compose config и smoke-тест.

Не копируйте исходные Makefile целиком: в них есть реальные сервисы, data
операции и инфраструктурные имена конкретных проектов.
