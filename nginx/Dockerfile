FROM nginx:1.18-alpine-perl

RUN apk add --no-cache nginx-mod-http-perl
RUN apk add --no-cache openssl

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf
COPY options-ssl-nginx.conf /etc/nginx/
COPY hsts.conf /etc/nginx/
RUN mkdir -p /customization
RUN mkdir -p /etc/symb_link_ssl
COPY nginx.sh /customization/nginx.sh
RUN chmod +x /customization/nginx.sh

EXPOSE 80
CMD ["/customization/nginx.sh"]