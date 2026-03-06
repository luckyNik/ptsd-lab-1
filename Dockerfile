FROM rust:1.76 AS builder
WORKDIR /usr/src/app

COPY . .

RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app

RUN apt-get update && apt-get install -y libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/app/target/release/lab-1 /usr/local/bin/lab-1

# Command to run the application
CMD ["lab-1"]