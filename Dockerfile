# Base image with Apache + PHP
FROM devopsedu/webapp:latest

# Set working directory
WORKDIR /var/www/html

# Copy ONLY the website folder from your repo into Apache document root
COPY ./website/ /var/www/html/

# Fix permissions (Apache readable)
RUN chmod -R 755 /var/www/html

# Expose Apache port
EXPOSE 80

# Run Apache in foreground
CMD ["apache2ctl", "-D", "FOREGROUND"]
