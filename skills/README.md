# Codex skills catalog

Навыки разделены на общие и проектные профили:

- `skills/shared` — переносимые навыки этого шаблонизатора;
- `templates/skills/mvdcake` — снимок навыков из `mvdcake`;
- `templates/skills/phpfiasgeocoder` — снимок навыков из
  `phpfiasgeocoder`.

Проектные профили намеренно сохраняют исходные пути, команды и архитектурные
ограничения. Устанавливайте их только в совместимый проект и адаптируйте вместе
с его `AGENTS.md`.

Список профилей:

```shell
make skills-list
```

Установка общих навыков:

```shell
make skills-install
```

Установка общих навыков и профиля:

```shell
make skills-install SKILLS_PROFILE=mvdcake
make skills-install SKILLS_PROFILE=phpfiasgeocoder
```

По умолчанию файлы копируются в `.agents/skills`. Установщик не перезаписывает
отличающийся существующий навык: сначала нужно явно сравнить и удалить либо
объединить его вручную.
