FROM eclipse-temurin:11-jdk-jammy
ARG HADOOP_VERSION=3.4.3
ARG PIG_VERSION=0.18.0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates procps python3 nano less gnupg && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
COPY docker/bigdata/download.py /usr/local/bin/download-archive.py
# Apache SHA-512 verifies Hadoop. Pig publishes a detached signature, verified
# against the project's KEYS over HTTPS (not an unauthenticated MD5 alone).
RUN --mount=type=cache,target=/var/cache/lab-downloads python3 /usr/local/bin/download-archive.py https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz hadoop.tgz \
 && curl -fL --retry 4 -o hadoop.sha512 https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz.sha512 \
 && expected=$(grep -Eo '[a-fA-F0-9]{128}' hadoop.sha512 | head -1) \
 && test -n "$expected" && echo "$expected  hadoop.tgz" | sha512sum -c - \
 && tar -xzf hadoop.tgz && mv hadoop-${HADOOP_VERSION} hadoop && rm hadoop.tgz hadoop.sha512
RUN --mount=type=cache,target=/var/cache/lab-downloads python3 /usr/local/bin/download-archive.py https://archive.apache.org/dist/pig/pig-${PIG_VERSION}/pig-${PIG_VERSION}.tar.gz pig.tgz \
 && curl -fL --retry 4 -o pig.asc https://archive.apache.org/dist/pig/pig-${PIG_VERSION}/pig-${PIG_VERSION}.tar.gz.asc \
 && curl -fL --retry 4 -o pig.keys https://downloads.apache.org/pig/KEYS \
 && gpg --batch --import pig.keys && gpg --batch --verify pig.asc pig.tgz \
 && tar -xzf pig.tgz && mv pig-${PIG_VERSION} pig && rm pig.tgz pig.asc pig.keys
ENV HADOOP_HOME=/opt/hadoop HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop PIG_HOME=/opt/pig
# Pig's intermediate-record reader still uses Collections 3. Hadoop 3.4 ships
# Collections 4 only; make Pig's bundled dependency available to YARN workers.
RUN cp /opt/pig/lib/hadoop3-runtime/commons-collections-3.2.2.jar /opt/hadoop/share/hadoop/common/lib/
ENV PATH="/opt/hadoop/bin:/opt/hadoop/sbin:/opt/pig/bin:${PATH}" \
    HADOOP_HEAPSIZE_MAX=256 HADOOP_CLIENT_OPTS="-Xmx512m" \
    HADOOP_NAMENODE_USER=lab HADOOP_DATANODE_USER=lab \
    YARN_RESOURCEMANAGER_USER=lab YARN_NODEMANAGER_USER=lab
COPY docker/bigdata/conf/ /opt/hadoop/etc/hadoop/
COPY docker/bigdata/entrypoint.sh /usr/local/bin/lab-entrypoint
RUN useradd -m -u 1000 lab && mkdir -p /data /workspace/artifacts /opt/hadoop/logs \
 && chown -R lab:lab /data /workspace /opt/hadoop/logs \
 && sed -i 's/\r$//' /usr/local/bin/lab-entrypoint && chmod +x /usr/local/bin/lab-entrypoint
COPY --chown=lab:lab labs /workspace/labs
USER lab
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/lab-entrypoint"]
