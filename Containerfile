FROM docker.io/library/golang:1.26-bookworm AS build

ARG VERSION=dev
# Defaults to the build platform's architecture: TARGETARCH is filled in by the
# builder, and an empty value makes the Go toolchain fall back to the host arch.
ARG TARGETARCH

# CGO off keeps the binary static, so the runtime image needs no libc.
ENV CGO_ENABLED=0 GOFLAGS=-mod=readonly GOTOOLCHAIN=local

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .

# -trimpath and -buildid= drop local paths and build IDs for reproducibility;
# -buildvcs=false keeps the result independent of whether .git is in the context.
RUN GOOS=linux GOARCH=${TARGETARCH} go build \
      -trimpath -buildvcs=false \
      -ldflags="-s -w -buildid= -X main.version=${VERSION}" \
      -o /out/app ./cmd/app

# distroless/static ships CA certificates, tzdata and /etc/passwd — no shell and
# no package manager, so an attacker who gets execution finds no tooling.
FROM gcr.io/distroless/static-debian12:nonroot AS runtime

ARG VERSION=experimental

# TODO change project name
LABEL org.opencontainers.image.title="myproject" \
      org.opencontainers.image.version="${VERSION}"

# Numeric uid, because Kubernetes runAsNonRoot cannot verify a username.
USER 65532:65532

# root-owned and read-only: the process cannot rewrite its own binary, and the
# container runs fine with --read-only.
COPY --from=build --chown=root:root --chmod=0555 /out/app /usr/local/bin/app

EXPOSE 8080

# Exec form: the app is PID 1 and receives SIGTERM directly.
ENTRYPOINT ["/usr/local/bin/app"]

# Run with: --read-only --cap-drop=ALL --security-opt=no-new-privileges
