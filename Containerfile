# syntax=docker/dockerfile:1.6
ARG FEDORA_VERSION=41

FROM quay.io/fedora/fedora:${FEDORA_VERSION} AS rpmbuilder

WORKDIR /workspace

RUN dnf -y install git rpm-build gzip tar && dnf clean all

COPY . /workspace

# Build SRPM from current source tree.
RUN ./packaging/rpm/build-srpm.sh --output-dir /workspace/packaging/rpm/dist

# Build binary RPM from SRPM.
RUN rpmbuild --rebuild /workspace/packaging/rpm/dist/modulix-launcher-*.src.rpm

# Collect binary RPM artifacts for next stage.
RUN mkdir -p /workspace/out && \
    find /root/rpmbuild/RPMS -type f -name 'modulix-launcher-*.rpm' -exec cp {} /workspace/out/ \;

FROM quay.io/fedora/fedora:${FEDORA_VERSION}

LABEL org.opencontainers.image.title="modulix-launcher" \
      org.opencontainers.image.description="Container image with modulix-launcher RPM installed and artifacts exported" \
      org.opencontainers.image.source="https://github.com/lightning-it/modulix-launcher"

# Runtime dependency declared by RPM.
RUN dnf -y install podman && dnf clean all

COPY --from=rpmbuilder /workspace/out/modulix-launcher-*.rpm /tmp/rpms/

# Install RPM and keep a copy inside image for extraction use-cases.
RUN dnf -y install /tmp/rpms/modulix-launcher-*.rpm && \
    mkdir -p /opt/modulix/rpms /usr/local/bin && \
    cp /tmp/rpms/modulix-launcher-*.rpm /opt/modulix/rpms/ && \
    ln -sf /usr/bin/modulix-launcher /usr/local/bin/modulix-launcher && \
    rm -rf /tmp/rpms && \
    dnf clean all

ENTRYPOINT ["/usr/local/bin/modulix-launcher"]
CMD ["--help"]

