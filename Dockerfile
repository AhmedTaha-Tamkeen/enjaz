FROM debian:bullseye-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa openjdk-11-jdk sudo bash \
    && apt-get clean

# Create a non-root user
RUN useradd -ms /bin/bash flutter
USER flutter
WORKDIR /home/flutter

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable

# Set environment variables
ENV PATH="/home/flutter/flutter/bin:/home/flutter/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter setup commands
RUN flutter doctor -v \
 && flutter config --enable-web

WORKDIR /app
EXPOSE 8080

# Use debug mode for hot reload support
CMD ["flutter", "run", "-d", "web-server", "--web-hostname=0.0.0.0", "--web-port=8080", "--debug"]