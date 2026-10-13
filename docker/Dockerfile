# Ambiente de desenvolvimento Flutter + Android SDK, sem nada instalado no host.
FROM debian:bookworm-slim

ARG FLUTTER_VERSION=3.47.5
ARG ANDROID_CMDLINE_TOOLS=11076708
ARG ANDROID_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG NODE_MAJOR=22
ARG UID=1000
ARG GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git unzip xz-utils zip libglu1-mesa \
      openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# Node.js + Firebase CLI (exigido pelo `flutterfire configure`)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g firebase-tools \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

# Usuário com o mesmo UID/GID do host → arquivos gerados em /app não ficam como root
RUN groupadd -g ${GID} dev && useradd -m -u ${UID} -g ${GID} -s /bin/bash dev

USER dev
ENV HOME=/home/dev \
    FLUTTER_HOME=/home/dev/flutter \
    PUB_CACHE=/home/dev/.pub-cache \
    ANDROID_HOME=/home/dev/android-sdk \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${HOME}/bin:${FLUTTER_HOME}/bin:${PUB_CACHE}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# Android SDK (o Gradle baixa sozinho platforms/build-tools/NDK extras que o projeto pedir)
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
 && curl -fsSL -o /tmp/cmdline-tools.zip \
      https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip \
 && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools \
 && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
 && rm /tmp/cmdline-tools.zip \
 && yes | sdkmanager --licenses > /dev/null \
 && sdkmanager "platform-tools" "platforms;android-${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" > /dev/null

# Flutter SDK
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
      https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
 # clone por tag fica em detached HEAD; uma branch local "stable" evita o aviso de canal desconhecido
 && git -C ${FLUTTER_HOME} config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' \
 && git -C ${FLUTTER_HOME} update-ref refs/remotes/origin/stable HEAD \
 && git -C ${FLUTTER_HOME} checkout -q -b stable --track origin/stable \
 && mkdir -p ${PUB_CACHE} ${HOME}/.gradle \
 && flutter config --no-analytics --enable-web --no-enable-linux-desktop --android-sdk ${ANDROID_HOME} \
 && flutter precache --android --web \
 && yes | flutter doctor --android-licenses > /dev/null \
 && flutter --version

# FlutterFire CLI num cache próprio: o ~/.pub-cache é encoberto pelo volume `pub-cache`.
# O wrapper roda o snapshot direto, sem mexer no PUB_CACHE do projeto.
RUN PUB_CACHE=${HOME}/.flutterfire-cli dart pub global activate flutterfire_cli \
 && mkdir -p ${HOME}/bin ${HOME}/.config \
 && printf '%s\n' '#!/bin/sh' \
      'exec dart "$(ls $HOME/.flutterfire-cli/global_packages/flutterfire_cli/bin/flutterfire.dart-*.snapshot | head -n1)" "$@"' \
      > ${HOME}/bin/flutterfire \
 && chmod +x ${HOME}/bin/flutterfire \
 && flutterfire --version

WORKDIR /app
EXPOSE 8080
CMD ["flutter", "doctor", "-v"]
