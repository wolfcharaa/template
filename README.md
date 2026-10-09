# Romanfedorskij Project Template

Персональный шаблон PHP-проектов: рабочий package scaffold в корне,
переносимые Docker/Makefile-заготовки и каталог Codex-навыков из проектов
`mvdcake` и `phpfiasgeocoder`.

## Что включено

- текущий PHP library scaffold с Composer, PHPStan, Rector, Testo и CI;
- `templates/docker/spiral` — Docker/Compose/Lua/PHP-runtime шаблон из
  `phpfiasgeocoder`, дополненный обезличенными Compose wrappers;
- `templates/make/cakephp-application.Makefile` — безопасный общий Makefile,
  извлечённый из практик `mvdcake`;
- `templates/docker/spiral/Makefile.fragment` — Spiral/RoadRunner Makefile из
  `phpfiasgeocoder`;
- `skills/shared` — общие навыки сопровождения шаблонов и Docker deployment;
- `templates/skills/mvdcake` и `templates/skills/phpfiasgeocoder` — точные
  проектные профили навыков.

## Быстрый старт

```shell
make help
make templates-list
make skills-list
make templates-check
```

Установить общие Codex-навыки в `.agents/skills`:

```shell
make skills-install
```

Добавить профиль конкретного проекта:

```shell
make skills-install SKILLS_PROFILE=mvdcake
make skills-install SKILLS_PROFILE=phpfiasgeocoder
```

Установщик не перезаписывает отличающиеся существующие навыки.

## Docker-шаблоны

Для Spiral-проекта перенесите содержимое `templates/docker/spiral` в
проектный `docker/`, затем адаптируйте service names, Compose files, registry,
env contract и health checks. Не накладывайте каталог поверх существующего
Docker-контура без предварительного diff.

Для CakePHP/multi-service проекта начните с
`templates/make/cakephp-application.Makefile` и возьмите только нужные wrappers
из `templates/docker/spiral/compose`.

Подробные границы и проверки описаны в
`skills/shared/docker-deployment/SKILL.md` и `templates/make/README.md`.
Исходные commits перечислены в `templates/SOURCES.md`.

## Исходный package scaffold

```shell
composer require romanfedorskij/template
```

## Проверка

```shell
make templates-check
make check
```

`templates-check` проверяет shell/Lua syntax, структуру всех `SKILL.md`,
smoke-сценарии Lua helpers и установку профиля навыков во временный каталог.
