# Contexto do projeto — Loja

> Arquivo de continuidade entre computadores (trabalho ↔ pessoal).
> **Regra:** toda alteração no projeto deve atualizar este arquivo (seções
> "Estado atual" e "Histórico") no mesmo commit. Ao iniciar em outra máquina:
> `git pull`, ler este arquivo e continuar do "Próximo passo".

## Visão geral

- App Flutter de loja virtual completa (curso), originalmente em **Flutter 1.22**,
  **sem null safety**, Firebase 0.x (`cloud_firestore ^0.13.5`,
  `firebase_auth ^0.16.0`, `firebase_storage ^3.1.5`, `cloud_functions ^0.5.0`,
  `firebase_messaging ^6.0.16`), `provider ^4.1.3`.
- Bem maior que o Loja-Virtual-Pro (mesma modernização, feita antes lá):
  77 arquivos em `lib/`, carrinho, checkout (Cielo), endereços (CEP Aberto),
  pedidos, lojas, painel admin (usuários, pedidos, produtos, seções da home),
  e Cloud Functions em TypeScript (`functions/`).
- Objetivo: modernizar para **Flutter 3.47.5**, um passo ("Dia") por vez.
- Branch de trabalho: `modernizacao` (principal: `master`).
- Remoto: https://github.com/ArthurMarianoNeto/Loja
- Firebase: projeto `loja-eeab9` (`.firebaserc`); Android
  `applicationId "br.com.arthurmariano.loja"`.

## Regras / preferências do usuário

- **Nada de Flutter/Dart/Android Studio instalado na máquina** — tudo roda via
  Docker: `docker compose run --rm flutter <comando>`.
- Progresso gradual: um "Dia" por vez, cada um com commit `Dia N: ...`.
- **A partir do Dia 3, cada Dia em sua própria branch** criada a partir de
  `modernizacao` (ex.: `dia-3-null-safety`); merge em `modernizacao` só após
  aprovação do usuário.
- Segredos: nunca versionar keystore (`*.jks`, `*.keystore`), `key.properties`,
  `.env` (já no `.gitignore`).
- Plataformas: **Android primeiro**, iOS depois; web para o painel admin.
- Material 3 aceito.
- Host: WSL2, UID/GID 1000 (se diferente, exportar `UID`/`GID` antes do build).

## Ambiente (Docker)

- `docker/Dockerfile` (cópia do Loja-Virtual-Pro): Debian bookworm-slim,
  Flutter 3.47.5, Android SDK 36 (build-tools 36.0.0), JDK 17, Node 22 +
  `firebase-tools`, `flutterfire_cli` (em `~/.flutterfire-cli` com wrapper
  `~/bin/flutterfire`), usuário `dev` com UID/GID do host.
- `docker-compose.yml`: imagem `loja/flutter:3.47.5`; serviço `flutter`
  (comandos avulsos) e `web` (porta 8080); volumes `pub-cache`,
  `gradle-cache` e `firebase-config`.

```bash
docker compose build                                   # primeira vez em cada máquina (~10 min)
docker compose run --rm flutter flutter doctor -v
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test
docker compose run --rm flutter flutter build apk
docker compose run --rm --service-ports web            # http://localhost:8080
```

## Roteiro da modernização

| Dia | Tarefa | Status |
|-----|--------|--------|
| 1 | Ambiente Docker (Flutter 3.47.5 + Android SDK 36) | ✅ concluído |
| 2 | Dependências / `pubspec.yaml` atualizados (trocar pacotes descontinuados) | ✅ concluído |
| 3 | Migração para null safety | ⏳ |
| 4 | Renomeações da API do Firebase (`FirebaseAuth`, `FirebaseFirestore`, etc.) | ⏳ |
| 5 | Inicialização do Firebase (`flutterfire configure` dentro do Docker) | ⏳ |
| 6 | Widgets / tema (Material 3) | ⏳ |
| 7 | Testes | ⏳ |
| 8 | Regenerar pasta Android + gerar APK | ⏳ |
| depois | Cloud Functions (`functions/`), painel admin web, iOS | — |

## Estado atual

- Último passo concluído: **Dia 2** (dependências) na branch `modernizacao`.
  - SDK `^3.13.0`; todos os pacotes diretos na última versão (`flutter pub
    outdated`: tudo em dia). Firebase: `firebase_core` 4.15, `cloud_firestore`
    6.10, `firebase_auth` 6.7, `firebase_storage` 13.6, `cloud_functions` 6.5,
    `firebase_messaging` 16.7.
  - Pacotes descontinuados trocados pelos sucessores (código ainda não migrado):
    `carousel_pro` → `carousel_slider`, `flushbar` → `another_flushbar`,
    `flutter_facebook_login` → `flutter_facebook_auth`,
    `flutter_signin_button` → `sign_in_button`,
    `alphabet_list_scroll_view` → `alphabet_list_view`, `gallery_saver` → `gal`.
    `faker` removido (só era importado). `flutter_launcher_icons` virou
    dev_dependency (chave `flutter_launcher_icons:` no pubspec).
  - `analysis_options.yaml` novo (`flutter_lints`, exclui build/android/ios/functions).
  - `flutter analyze`: 779 issues / 504 erros (esperado; Dias 3–6).
- **Próximo passo:** Dia 3 — null safety (branch `dia-3-null-safety`).
- Pendências conhecidas:
  - Imports `file:///C:/Users/thies/...` em `order_tile.dart`,
    `confirmation_screen.dart`, `section_header.dart` (corrigir no Dia 3).
  - `main()` chama a Cloud Function de teste `addMessage` a cada abertura.
  - `recuperar_senha.txt` na raiz: anotação do curso; a recuperação de senha já
    está em `user_manager.dart`/`login_screen.dart` — perguntar se pode remover.
  - `functions/` (Node 14, firebase-functions 3) também precisará de atualização.

## Histórico

- **2026-10-13** — Dia 1: `docker/Dockerfile` (igual ao Loja-Virtual-Pro),
  `docker-compose.yml`, README com instruções Docker, `.gitignore` protege
  keystores/`key.properties`/`.env`; criado este `CLAUDE.md`.
- **2026-10-13** — Dia 2: dependências atualizadas (Firebase 4.x/6.x/13.x/16.x,
  provider 6, flutter_lints 6), pacotes descontinuados trocados pelos
  sucessores, `analysis_options.yaml` novo; analyze com 504 erros.
