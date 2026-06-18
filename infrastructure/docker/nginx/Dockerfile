FROM nginx:alpine
# The nginx:alpine image automatically runs envsubst on files in this directory before starting
COPY templates/default.conf.template /etc/nginx/templates/
EXPOSE 80
