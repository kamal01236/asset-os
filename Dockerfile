# Multi-stage: Flutter web build → nginx static SPA
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Cache deps when pubspec is unchanged
COPY apps/web/pubspec.yaml apps/web/pubspec.lock ./
RUN flutter config --enable-web \
  && flutter pub get

COPY apps/web/ ./
RUN flutter pub get \
  && flutter build web --release

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
