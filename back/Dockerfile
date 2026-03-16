# Build stage
FROM rust:1.94-slim as builder

WORKDIR /app

# Install dependencies for SQLx
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Copy source code
COPY src ./src
COPY migrations ./migrations

# Build the application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary from builder
COPY --from=builder /app/target/release/liftup-backend /app/liftup-backend

# Copy migrations
COPY --from=builder /app/migrations /app/migrations

# Expose the port
EXPOSE 8080

# Run the binary
CMD ["/app/liftup-backend"]
