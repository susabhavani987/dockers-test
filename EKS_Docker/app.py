
import os
from pyspark.sql import SparkSession, functions as F

BUCKET = os.getenv("S3_BUCKET", "testbuckaltnewvijay")
OUTPUT_PREFIX = os.getenv("OUTPUT_PREFIX", "eks-pyspark-output")
OUTPUT_PATH = f"s3://{BUCKET}/{OUTPUT_PREFIX}/"

spark = (
    SparkSession.builder
    .appName("EKS-PySpark-Demo")
    .getOrCreate()
)

# Example dataset
data = [("Alice", 34), ("Bob", 45), ("Cathy", 29), ("Dan", 33)]
df = spark.createDataFrame(data, ["name", "age"])

# Simple transform
result = df.filter(F.col("age") > 30)

# Write to S3 (Parquet)
(
    result
    .coalesce(1)
    .write
    .mode("overwrite")
    .parquet(OUTPUT_PATH)
)

print(f"Wrote {result.count()} rows to {OUTPUT_PATH}")
spark.stop()
