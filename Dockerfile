FROM rust:latest AS builder
WORKDIR /usr/src/app

COPY . .
RUN cargo build --release

FROM rust:latest AS tester
WORKDIR /usr/src/app

COPY . .
CMD ["cargo", "test", "--workspace"]

FROM debian:bookworm-slim AS runtime
WORKDIR /app

RUN apt-get update && apt-get install -y libssl-dev ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/src/app/target/release/lab-1 /usr/local/bin/lab-1

CMD ["lab-1"]