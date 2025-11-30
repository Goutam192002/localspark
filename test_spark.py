from pyspark import SparkContext, SparkConf
from pyspark.sql import SparkSession
import os

# get host path to spark-events directory
script_dir = os.path.dirname(os.path.abspath(__file__))
events_dir = os.path.join(script_dir, "spark-events")
master_url = "spark://localhost:7077"

# check if running in container
if os.path.exists("/opt/spark"):
    events_dir = "/tmp/spark-events"
    master_url = "spark://spark-master:7077"


os.makedirs(events_dir, exist_ok=True)

conf = SparkConf().setAppName("Test Spark") \
    .setMaster(master_url) \
    .set("spark.eventLog.enabled", "true") \
    .set("spark.eventLog.dir", f"file://{events_dir}")

sc = SparkContext(conf=conf)

spark = SparkSession.builder.getOrCreate()

df = spark.createDataFrame([(1, "John"), (2, "Jane"), (3, "Jim")], ["id", "name"])
df.show()

spark.stop()
sc.stop()
print("Spark session stopped")
