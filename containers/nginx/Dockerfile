FROM nginx:1.11

EXPOSE 443
EXPOSE 80

COPY ./conf /etc/nginx/conf.d/

CMD chown -R www-data:www-data /var/www/storage-files && nginx -g "daemon off;"
