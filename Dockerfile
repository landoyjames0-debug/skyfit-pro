# ============================================================
# Stage 1: Build Flutter Web App
# M4 - DevOps: Multi-stage Dockerfile for optimized image size
# ============================================================
FROM debian:bookworm-slim AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
ARG FLUTTER_VERSION=3.29.0
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable Flutter web
RUN flutter doctor --verbose && flutter config --enable-web

WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

# Build-time secrets injected via --dart-define (M4 Security)
ARG FIREBASE_API_KEY
ARG FIREBASE_APP_ID
ARG FIREBASE_MESSAGING_SENDER_ID
ARG FIREBASE_PROJECT_ID
ARG FIREBASE_AUTH_DOMAIN
ARG FIREBASE_STORAGE_BUCKET
ARG OPENWEATHER_API_KEY
ARG GOOGLE_WEB_CLIENT_ID

# Build Flutter web with all secrets injected at compile time
RUN flutter build web --release \
    --dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY} \
    --dart-define=FIREBASE_APP_ID=${FIREBASE_APP_ID} \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID} \
    --dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID} \
    --dart-define=FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN} \
    --dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET} \
    --dart-define=OPENWEATHER_API_KEY=${OPENWEATHER_API_KEY} \
    --dart-define=GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID}

# Inject GOOGLE_WEB_CLIENT_ID into the built index.html <meta> tag
# This is needed because the GSI script reads it from the DOM at runtime,
# not from Dart — so dart-define alone is not enough for Google Sign-In on web.
RUN sed -i \
    "s|content=\"YOUR_WEB_CLIENT_ID_PLACEHOLDER\"|content=\"${GOOGLE_WEB_CLIENT_ID}\"|g" \
    /app/build/web/index.html

# ============================================================
# Stage 2: Serve with nginx (lightweight production image)
# ============================================================
FROM nginx:alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html

# Custom nginx config for Flutter SPA routing
RUN echo 'server { \
    listen 8080; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
