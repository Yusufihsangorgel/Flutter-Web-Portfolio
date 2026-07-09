FROM nginx:alpine
RUN printf "gzip on;\n\
gzip_vary on;\n\
gzip_proxied any;\n\
gzip_comp_level 6;\n\
gzip_min_length 256;\n\
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/wasm font/woff2;\n\
\n\
server_tokens off;\n\
\n\
server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    etag on;\n\
\n\
    # Security headers\n\
    add_header X-Content-Type-Options \"nosniff\" always;\n\
    add_header X-Frame-Options \"SAMEORIGIN\" always;\n\
    add_header Referrer-Policy \"strict-origin-when-cross-origin\" always;\n\
    add_header Permissions-Policy \"camera=(), microphone=(), geolocation=()\" always;\n\
    add_header X-XSS-Protection \"1; mode=block\" always;\n\
    add_header Content-Security-Policy \"default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://analytics.developeryusuf.com https://pagead2.googlesyndication.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https: blob:; connect-src 'self' https://api.rss2json.com https://api.github.com https://formspree.io https://analytics.developeryusuf.com; frame-ancestors 'self';\" always;\n\
\n\
    location / {\n\
        try_files \$uri \$uri/ /index.html;\n\
    }\n\
    location ~* \\.(html|js|json)\$ {\n\
        add_header Cache-Control \"no-cache, must-revalidate\";\n\
    }\n\
    location ~* \\.(png|jpg|jpeg|gif|ico|svg|woff2?|wasm|css|otf|ttf) {\n\
        expires 1y;\n\
        add_header Cache-Control \"public, immutable\";\n\
    }\n\
}" > /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
