# Use Ubuntu as base image for compatibility
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV SRVPORT=4499

# Install required packages and clean up in one layer to reduce image size
RUN apt-get update && apt-get install -y \
    fortune-mod \
    cowsay \
    socat \
    netcat-openbsd \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Add cowsay to PATH so it can be found
ENV PATH="/usr/games:${PATH}"

# Create app directory
WORKDIR /app

# Copy application script
COPY wisecow.sh .

# Make script executable
RUN chmod +x wisecow.sh

# Create non-root user for security
RUN useradd -m -u 1001 -s /bin/bash wisecow && \
    chown -R wisecow:wisecow /app

# Switch to non-root user
USER wisecow

# Expose the application port
EXPOSE 4499

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:4499/ || exit 1

# Run the application
CMD ["./wisecow.sh"]