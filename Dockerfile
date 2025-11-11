# Use base image requested
FROM devopsedu/webapp

# Set working directory as appropriate to the base image's web root
# Example: if base image serves from /var/www/html
WORKDIR /var/www/html

# Copy application files into container (adjust paths if needed)
COPY ./www/ /var/www/html/

# Ensure proper permissions (optional)
RUN chown -R www-data:www-data /var/www/html

# Expose port 80 (if not already present)
EXPOSE 80

# If base image already defines CMD/ENTRYPOINT, no need to redefine
# Otherwise provide a command to run apache/php-fpm

