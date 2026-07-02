# MangaLib iOS (Flutter)

Клиент MangaLib + SlashLib для iOS: каталог, поиск, читалка глав, авторизация через lib.social (WebView, перехват токена).

## Сборка через Codemagic (без Mac)

1. Запушь этот репозиторий на GitHub.
2. Зарегистрируйся на [codemagic.io](https://codemagic.io) (бесплатный тир — 500 минут/мес на macOS M2).
3. Add application → выбери репозиторий → Codemagic сам найдёт `codemagic.yaml`.
4. Start new build → workflow `ios-unsigned`.
5. Скачай артефакт `mangalib_app.ipa`.

## Установка на iPhone (бесплатно, без Developer-аккаунта)

1. Поставь [AltStore](https://altstore.io) или [SideStore](https://sidestore.io) на iPhone (нужен AltServer на ПК для первой установки).
2. Открой скачанный `.ipa` через AltStore — он подпишет его твоим Apple ID.
3. Ограничение бесплатного Apple ID: подпись живёт 7 дней, AltStore авто-продлевает при подключении к той же Wi-Fi сети, что и AltServer.

## Структура

- `lib/api.dart` — клиент API `api.cdnlibs.org` (общий для mangalib/slashlib, переключение через заголовок `Site-Id`)
- `lib/screens/catalog.dart` — каталог + поиск + переключатель сайта
- `lib/screens/title.dart` — страница тайтла и список глав
- `lib/screens/reader.dart` — читалка (вертикальный скролл, зум, перелистывание глав)
- `lib/screens/profile.dart` — авторизация (WebView → токен из localStorage) и профиль
- `codemagic.yaml` — CI: генерирует `ios/`, собирает неподписанный IPA

Папка `ios/` не хранится в репо — Codemagic генерирует её на каждой сборке (`flutter create`).
