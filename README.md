# loja

Loja virtual em Flutter + Firebase (curso).

## Ambiente de desenvolvimento (Docker)

Nenhum SDK precisa ser instalado na máquina: Flutter 3.47.5, Android SDK 36 e
JDK 17, Node 22 + Firebase CLI e FlutterFire CLI rodam dentro do contêiner, com o código montado em `/app`.

```bash
docker compose build                                   # primeira vez (~10 min)
docker compose run --rm flutter flutter doctor -v
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test
docker compose run --rm flutter flutter build apk
docker compose run --rm --service-ports web            # http://localhost:8080 ('r' = hot reload)
```

Os caches de pacotes Dart e Gradle ficam em volumes nomeados (`pub-cache`,
`gradle-cache`). Se o seu UID/GID não for 1000, exporte `UID` e `GID` antes do build.
