FROM nginx:1.18-alpine-perl

RUN apk add --no-cache nginx-mod-http-perl
RUN apk add --no-cache openssl

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/sites/default.conf
COPY options-ssl-nginx.conf /etc/nginx/
COPY hsts.conf /etc/nginx/
COPY nginx.sh /customization/
RUN chmod +x /customization/nginx.sh

EXPOSE 80
CMD ["/customization/nginx.sh"]