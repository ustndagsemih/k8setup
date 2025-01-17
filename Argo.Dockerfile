####################################################################################################
# Install AWSCLI
####################################################################################################
FROM ubuntu:focal as awscli

ARG AWSCLI_DEFAULT_VERSION

# Note - Latest version of AWS - https://github.com/aws/aws-cli/blob/v2/CHANGELOG.rst
ENV AWSCLI_VERSION="${AWSCLI_DEFAULT_VERSION:-2.8.5}"

WORKDIR /awscli

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    unzip \
    ; \
  rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  ARCH="$(dpkg --print-architecture)"; ARCH="${ARCH##*-}"; \
  case "$ARCH" in \
    'arm64') \
      AWSCLI_ARCH='aarch64'; \
      wget -qO awscli.zip https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}-${AWSCLI_VERSION}.zip && unzip -qq awscli.zip;\
      ;; \
    'amd64') \
      AWSCLI_ARCH='x86_64'; \
      wget -qO awscli.zip https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}-${AWSCLI_VERSION}.zip && unzip -qq awscli.zip;\
      ;; \
    *) echo >&2 "error: unsupported architecture '$ARCH' (likely packaging update needed)"; exit 1 ;; \
  esac;

####################################################################################################
# Final image for Jenkins
# https://quay.io/repository/argoproj/kubectl-argo-rollouts?tab=tags
####################################################################################################
FROM quay.io/argoproj/kubectl-argo-rollouts:v1.3.1

# Use numeric user, allows kubernetes to identify this user as being
# non-root when we use a security context with runAsNonRoot: true
#USER 999
USER root

COPY --from=awscli  /awscli/aws/ /aws

RUN chmod -R 755 /aws
RUN /aws/install -i /usr/local/aws-cli -b /usr/local/bin

WORKDIR /home/argo-rollouts

ENTRYPOINT ["/bin/kubectl-argo-rollouts"]

CMD ["dashboard"]
