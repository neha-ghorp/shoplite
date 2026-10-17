# Jenkins controller with the deploy tools baked in: versions live in Git, not on a server.
FROM jenkins/jenkins:lts-jdk21

USER root
ARG TARGETARCH
ARG KUBECTL_VERSION=v1.37.0
ARG HELM_VERSION=v4.3.0

RUN apt-get update && apt-get install -y --no-install-recommends curl jq \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
 && chmod +x /usr/local/bin/kubectl \
 && curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz -C /tmp \
 && mv /tmp/linux-${TARGETARCH}/helm /usr/local/bin/helm \
 # The repo is mounted from the host (different owner); allow git to read it
 && git config --system --add safe.directory '*'

# Docker CLI only; builds run on the host's Docker engine through the mounted socket
COPY --from=docker:29-cli /usr/local/bin/docker /usr/local/bin/docker

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# No setup wizard: everything is configured from casc.yaml (Configuration as Code).
# ALLOW_LOCAL_CHECKOUT: lab only, so Jenkins can clone the repo mounted at /repo.
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true"
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/casc.yaml
COPY casc.yaml /usr/share/jenkins/casc.yaml

# Lab shortcut: root, to use the Docker socket. In production: agents (e.g. pods with
# Kaniko/BuildKit), never builds on the controller, never the host's Docker socket.
USER root
