FROM nginx:1.29.5-alpine@sha256:1eff5a5f3fcf8431a0abb7eddf5471fec24e5e1905a2581aeacdb07a4479b92b AS source-check

WORKDIR /workspace
COPY analysis_options.yaml package.json package-lock.json pubspec.yaml pubspec.lock ./
COPY assets assets
COPY lib lib
COPY packages packages
COPY tool tool
COPY web web
COPY build/web/assets/assets/build/source_manifest.sha256 /tmp/source_manifest.sha256
RUN sha256sum -c /tmp/source_manifest.sha256 && touch /source-verified

FROM nginx:1.29.5-alpine@sha256:1eff5a5f3fcf8431a0abb7eddf5471fec24e5e1905a2581aeacdb07a4479b92b

COPY --from=source-check /source-verified /tmp/source-verified
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html

RUN test -f /tmp/source-verified && rm /tmp/source-verified && nginx -t

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
