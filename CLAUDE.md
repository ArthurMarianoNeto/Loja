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
| 2 | Dependências / `pubspec.yaml` atualizados (trocar pacotes descontinuados) | ⏳ |
| 3 | Migração para null safety | ⏳ |
| 4 | Renomeações da API do Firebase (`FirebaseAuth`, `FirebaseFirestore`, etc.) | ⏳ |
| 5 | Inicialização do Firebase (`flutterfire configure` dentro do Docker) | ⏳ |
| 6 | Widgets / tema (Material 3) | ⏳ |
| 7 | Testes | ⏳ |
| 8 | Regenerar pasta Android + gerar APK | ⏳ |
| depois | Cloud Functions (`functions/`), painel admin web, iOS | — |

## Estado atual

- Último passo concluído: **Dia 1** (ambiente Docker) na branch `modernizacao`.
- **Próximo passo:** Dia 2 — atualizar o `pubspec.yaml`. Pacotes sem versão
  compatível com Dart 3 a substituir (levantar uso em `lib/` antes):
  `carousel_pro`, `alphabet_list_scroll_view`, `flushbar`,
  `flutter_facebook_login`, `flutter_signin_button`, `gallery_saver`,
  `flip_card` (verificar), `image_cropper`/`image_picker` (API mudou),
  `flutter_staggered_grid_view` (API mudou na 0.5+), `geolocator`, `dio`,
  `uuid`, `url_launcher`, `map_launcher`, `brasil_fields`.
- Pendências conhecidas:
  - `recuperar_senha.txt` na raiz: anotação do curso (código antigo com
    `FlatButton`/`scaffoldKey`); a recuperação de senha já está em
    `user_manager.dart`/`login_screen.dart` — perguntar ao usuário se pode remover.

## Histórico

- **2026-10-13** — Dia 1: `docker/Dockerfile` (igual ao Loja-Virtual-Pro),
  `docker-compose.yml`, README com instruções Docker, `.gitignore` protege
  keystores/`key.properties`/`.env`; criado este `CLAUDE.md`.
