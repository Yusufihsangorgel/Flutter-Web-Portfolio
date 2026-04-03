FROM nginx:alpine
RUN printf "server {\n    listen 80;\n    root /usr/share/nginx/html;\n    index index.html;\n    etag on;\n    location / {\n        try_files \$uri \$uri/ /index.html;\n    }\n    location ~* \\.(html|js|json)\$ {\n        add_header Cache-Control \"no-cache, must-revalidate\";\n    }\n    location ~* \\.(png|jpg|jpeg|gif|ico|svg|woff2?|wasm|css|otf|ttf) {\n        expires 1y;\n        add_header Cache-Control \"public, immutable\";\n    }\n}" > /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
