# Stage 1: Build the application
FROM alpine:3.17.3 AS build

# Install build dependencies
RUN apk add --no-cache build-base bsd-compat-headers

# Download and extract Lighttpd source code
RUN wget https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-1.4.69.tar.gz && \
    tar xvzf lighttpd-1.4.69.tar.gz && \
    rm lighttpd-1.4.69.tar.gz

WORKDIR /lighttpd-1.4.69
# Add predefined static plugins
ADD resources/plugin-static.h src/plugin-static.h

# Configure and build Lighttpd
RUN LDFLAGS=--static LIGHTTPD_STATIC=yes \
    ./configure --prefix=/usr/local/lighttpd --without-pcre2 --with-zlib=no  && \
    make && \
    make install

# Strip main binary file
RUN strip -s /usr/local/lighttpd/sbin/lighttpd


# Stage 2: Create the final image
FROM scratch

ENV PORT=80

# Copy only the necessary file from the build stage
COPY --from=build /usr/local/lighttpd/sbin/lighttpd /bin/lighttpd

# Add config file
ADD resources/lighttpd.conf /etc/lighttpd.conf

# Add index.html file
ADD resources/index.html /www/index.html

# Add temporary directory
ADD resources/tmp /var/tmp

# Expose port $PORT for HTTP traffic
EXPOSE $PORT

# Start Lighttpd
CMD ["/bin/lighttpd", "-D", "-f", "/etc/lighttpd.conf"]
