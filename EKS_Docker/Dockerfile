
FROM openjdk:11-jre-slim

ENV SPARK_VERSION=3.5.0
ENV HADOOP_VERSION=3
ENV PATH="$PATH:/spark/bin"
WORKDIR /app

# System deps + Python + PySpark
RUN apt-get update && apt-get install -y curl python3 python3-pip &&         pip3 install --no-cache-dir pyspark==3.5.0 boto3 &&         curl -fsSL https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -o spark.tgz &&         tar xzf spark.tgz &&         mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /spark &&         rm spark.tgz &&         apt-get clean && rm -rf /var/lib/apt/lists/*

COPY app.py /app/app.py

# Optionally allow extra args via ARGS env var
ENV APP_ARGS=""
CMD ["bash", "-lc", "spark-submit $APP_ARGS /app/app.py"]
