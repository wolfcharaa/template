# PHP Project Template

Переиспользуемый PHP project scaffold с Composer, Docker/Makefile-заготовками
и локальными Codex-навыками в обычной структуре проекта.

## Что включено

- рабочий PHP library scaffold с Composer, PHPStan, Rector, Testo и CI;
- `templates/docker/spiral` — Docker/Compose/Lua/PHP-runtime шаблон для
  Spiral/RoadRunner;
- `templates/make/cakephp-application.Makefile` — общий lifecycle/release
  Makefile для CakePHP и других multi-service PHP-приложений;
- `.agents/skills` — активные навыки для CakePHP, Spiral, React/Inertia,
  Docker deployment и сопровождения шаблона.

После создания проекта удалите навыки и framework-шаблоны, которые не
соответствуют выбранному стеку. Основные правила проекта оставляйте в
`AGENTS.md`, а подробные повторяемые workflow — в `.agents/skills`.

## Быстрый старт

```shell
make help
make templates-list
make templates-check
```

## Docker-шаблоны

Для Spiral-проекта перенесите содержимое `templates/docker/spiral` в
проектный `docker/`, затем адаптируйте service names, Compose files, registry,
env contract и health checks. Не накладывайте каталог поверх существующего
Docker-контура без предварительного diff.

Для CakePHP/multi-service проекта начните с
`templates/make/cakephp-application.Makefile` и возьмите только нужные wrappers
из `templates/docker/spiral/compose`.

Подробные границы и проверки описаны в
`.agents/skills/docker-deployment/SKILL.md` и `templates/make/README.md`.

## Исходный package scaffold

```shell
composer require romanfedorskij/template
```

## Локальная отладка

В development-окружении вместо прямой зависимости от Symfony VarDumper
используется Buggregator Trap. После установки зависимостей локальный сервер
запускается без Docker:

```shell
vendor/bin/trap --ui=8000
```

Веб-интерфейс будет доступен на `http://127.0.0.1:8000`; без `--ui`
Trap выводит события прямо в терминал.

Для отправки значений используйте `trap($value)`, а для возврата значения
после дампа — `tr($value)`. Сам Trap продолжает использовать и расширять
Symfony VarDumper внутри, поэтому привычная функция `dump()` также остаётся
доступной.

## Проверка

```shell
make templates-check
make check
```

`templates-check` проверяет shell/Lua syntax, структуру всех локальных
`SKILL.md` и smoke-сценарии Lua helpers.
