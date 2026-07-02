# MangaLib iOS (WebView)

Простая обёртка: приложение открывает mangalib.me / slashlib.me внутри себя (полноценный сайт, без переизобретения интерфейса). Авторизация, каталог, читалка — всё как на сайте, через мобильный User-Agent.

## Возможности

- Переключатель MangaLib ↔ SlashLib (кнопка в шапке)
- Кнопка обновить страницу
- Кнопка "назад" по истории сайта (и системный swipe-back на iOS)

## Сборка через Codemagic (без Mac)

1. Запушь этот репозиторий на GitHub.
2. codemagic.io → Add application → выбери репозиторий (подхватит `codemagic.yaml`).
3. Switch to YAML configuration → выбери workflow `ios-unsigned` → Start new build.
4. Скачай артефакт `mangalib_app.ipa`.

## Установка на iPhone (бесплатно, без Developer-аккаунта)

1. AltServer на ПК (altstore.io) + AltStore на iPhone.
2. Открой `.ipa` через AltStore → My Apps → + → подпишет твоим Apple ID.
3. Ограничение: сертификат живёт 7 дней, AltStore продлевает сам при подключении к той же Wi-Fi, что и AltServer.

## Структура

- `lib/main.dart` — вся логика: WebView + переключение сайта
- `codemagic.yaml` — CI: генерирует `ios/`, собирает неподписанный IPA

Папка `ios/` не хранится в репо — Codemagic генерирует её на каждой сборке (`flutter create`).
