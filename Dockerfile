FROM nginx:alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy JSON files to html directory
COPY data /usr/share/nginx/html/api/store/v2

EXPOSE 80