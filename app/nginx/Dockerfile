FROM nginx:latest

# Copy custom nginx config to replace the default
COPY nginx.conf /etc/nginx/nginx.conf

# Copy fallback HTML file to the default location
COPY fallback.html /usr/share/nginx/html/fallback.html

# Expose port 80
EXPOSE 80

