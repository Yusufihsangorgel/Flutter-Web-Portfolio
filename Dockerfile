# Stage 1: Build Flutter web
FROM ghcr.io/cirruslabs/flutter:3.41.0 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

# Stage 2: Serve with nginx
FROM nginx:alpine
RUN printf "server {\n    listen 80;\n    root /usr/share/nginx/html;\n    index index.html;\n    location / {\n        try_files \$uri \$uri/ /index.html;\n    }\n    location ~* \.html\$ {\n        add_header Cache-Control \"no-cache\";\n    }\n    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?|wasm) {\n        expires 1y;\n        add_header Cache-Control \"public, immutable\";\n    }\n}" > /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
