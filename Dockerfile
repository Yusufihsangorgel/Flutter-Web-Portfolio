FROM nginx:alpine

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html

RUN nginx -t

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
