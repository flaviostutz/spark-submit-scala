FROM bde2020/spark-submit:2.4.5-hadoop2.7

ENV ENABLE_INIT_DAEMON 'false'
ENV SPARK_APPLICATION_JAR_LOCATION '/app/app.jar'
ENV SPARK_APPLICATION_MAIN_CLASS 'app.Main'
ENV SPARK_APPLICATION_ARGS ''

ARG SCALA_VERSION=2.13.1
ARG SCALA_HOME=/usr/share/scala
ARG SBT_VERSION=1.3.8

#install scala
RUN apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    apk add --no-cache bash && \
    cd "/tmp" && \
    wget "https://downloads.typesafe.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" && \
    tar xzf "scala-${SCALA_VERSION}.tgz" && \
    mkdir "${SCALA_HOME}" && \
    rm "/tmp/scala-${SCALA_VERSION}/bin/"*.bat && \
    mv "/tmp/scala-${SCALA_VERSION}/bin" "/tmp/scala-${SCALA_VERSION}/lib" "${SCALA_HOME}" && \
    ln -s "${SCALA_HOME}/bin/"* "/usr/bin/" && \
    apk del .build-dependencies && \
    rm -rf "/tmp/"*

#install sbt
RUN echo "$SCALA_VERSION $SBT_VERSION" && \
    apk add --no-cache bash curl bc ca-certificates && \
    update-ca-certificates && \
    scala -version && \
    scalac -version && \
    curl -fL https://github.com/sbt/sbt/releases/download/v$SBT_VERSION/sbt-$SBT_VERSION.tgz | tar xfz - -C /usr/local && \
    $(mv /usr/local/sbt-launcher-packaging-$SBT_VERSION /usr/local/sbt || true) && \
    ln -s /usr/local/sbt/bin/* /usr/local/bin/ && \
    apk del curl && \
    sbt sbtVersion

#warmup
ADD /app /app
WORKDIR /app
RUN sbt assembly && \
    rm -rf /app

#make run fail if submit fails
RUN sed -i -e 's|/bash|/bash -e|g' /submit.sh

