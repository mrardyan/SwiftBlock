# ================================
# Build Image
# ================================
FROM swift:5.10-noble as build

# Install OS updates and build dependencies
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q install -y libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up build directory
WORKDIR /build

# Copy Swift PM dependencies & manifests
COPY ./Package.* ./
RUN swift package resolve

# Copy source code
COPY . .

# Build release binary
RUN swift build -c release --product Run

# ================================
# Production Stage Image
# ================================
FROM swift:5.10-noble-slim as run

# Create vapor user & group
RUN useradd --user-group --no-create-home --system --skel /dev/null vapor

WORKDIR /app

# Copy binary from build stage
COPY --from=build /build/.build/release/Run /app/Run

# Expose server port
EXPOSE 8080

# Run as non-root user
USER vapor:vapor

ENTRYPOINT ["./Run", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
