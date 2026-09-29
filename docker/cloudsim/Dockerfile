FROM maven:3.9-eclipse-temurin-21 AS builder
ARG CLOUDSIM_COMMIT=9a414ff15df0caa2978efb5bcd6e6180fa58bb66
WORKDIR /src
RUN curl -fL --retry 4 https://codeload.github.com/Cloudslab/cloudsim/tar.gz/${CLOUDSIM_COMMIT} | tar -xz --strip-components=1 \
 && mvn -B -pl modules/cloudsim -am package -DskipTests \
 && mvn -B -f modules/cloudsim/pom.xml dependency:copy-dependencies -DincludeScope=runtime -DoutputDirectory=/opt/cloudsim/lib \
 && cp modules/cloudsim/target/cloudsim-7.0.1.jar /opt/cloudsim/lib/
# Reuse the same Java 21 base layers as the builder for faster offline packaging.
FROM maven:3.9-eclipse-temurin-21
COPY --from=builder /opt/cloudsim /opt/cloudsim
COPY --from=builder /src/documentation /opt/cloudsim/upstream-documentation
COPY labs/03-cloudsim /workspace/labs/03-cloudsim
WORKDIR /workspace
ENTRYPOINT ["bash", "/workspace/labs/03-cloudsim/run.sh"]
