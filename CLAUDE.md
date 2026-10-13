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
| 3 | Migração para null safety | ✅ concluído (merge em `modernizacao`) |
| 4 | Renomeações da API do Firebase (`FirebaseAuth`, `FirebaseFirestore`, etc.) + APIs dos pacotes novos | ✅ concluído (merge em `modernizacao`) |
| 5 | Inicialização do Firebase (`firebase_options.dart` + `Firebase.initializeApp`) | ✅ concluído (merge em `modernizacao`) |
| 6 | Widgets / tema (Material 3) | ✅ concluído (merge em `modernizacao`) |
| 7 | Testes | ✅ concluído (merge em `modernizacao`) |
| 8 | Regenerar pasta Android + gerar APK | ⏳ |
| depois | Cloud Functions (`functions/`), painel admin web, iOS | — |

## Estado atual

- Último passo concluído: **Dia 7** (testes), mergeado em `modernizacao`.
  - Injeção de dependência: managers recebem `FirebaseFirestore`/`FirebaseAuth`
    opcionais; `UserManager` recebe `getToken` (FCM) e `CheckoutManager`
    recebe `CieloPayment`. Models (`Product`, `Section`, `CartProduct`,
    `Order`, `AppUser`) usam o Firestore do próprio documento
    (`document.reference.firestore`) ou resolvem o `instance` só no uso.
    Parâmetros nomeados privados (`this._firestore`, recurso do Dart 3.13).
  - 76 testes: helpers, models, managers com `fake_cloud_firestore` +
    `firebase_auth_mocks` + `mock_exceptions` (inclui checkout completo com
    Cielo simulada: autorização, baixa de estoque em transação, captura,
    cancelamento sem estoque) e telas (login, cadastro, carrinho,
    `ProductListTile`). `test/widget_test.dart` (contador) removido.
  - Bugs achados pelos testes e corrigidos: `Product.fromDocument` quebrava
    com campo ausente; produto apagado criava item vazio no carrinho/pedido;
    `ProductListTile` estourava 4 px sem estoque (altura 100 → 110);
    coordenadas inteiras no `aux/delivery`.
  - `SafeNetworkImage` (`lib/common/`): produto sem imagem ou URL quebrada
    mostra um ícone em vez de erro (`images.first` quebrava com lista vazia).
  - `flutter analyze`: **0 issues**. `flutter test`: **76/76 passando**.
- **Próximo passo:** Dia 8 — regenerar pasta Android + gerar APK.
- Pendências conhecidas:
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
- **2026-10-13** — Dia 3: null safety em `lib/` (branch `dia-3-null-safety`),
  imports `file:///` corrigidos; analyze de 504 para 203 erros. Mergeado em
  `modernizacao` (usuário pediu para executar todos os Dias no mesmo dia).
- **2026-10-13** — Dia 4: APIs do Firebase e dos pacotes trocados (branch
  `dia-4-firebase-api`), `User` → `AppUser`, carrossel próprio; analyze de 203
  para 39 erros. Mergeado em `modernizacao`.
- **2026-10-13** — Dia 5: `firebase_options.dart` (Android) e
  `Firebase.initializeApp` no `main()` (branch `dia-5-firebase-init`); chamada
  de teste `addMessage` removida. Mergeado em `modernizacao`.
- **2026-10-13** — Dia 6: Material 3 (branch `dia-6-material3`), widgets
  removidos substituídos, telas de login/cadastro `StatefulWidget`;
  `flutter analyze` com 0 issues. Mergeado em `modernizacao`.
- **2026-10-13** — Dia 7: testes (branch `dia-7-testes`): 76 testes,
  injeção de dependência nos managers, `SafeNetworkImage`, bugs corrigidos.
  Mergeado em `modernizacao`.
