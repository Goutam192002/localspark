from pyspark import SparkContext, SparkConf
from pyspark.sql import SparkSession
import os

# get host path to spark-events directory
script_dir = os.path.dirname(os.path.abspath(__file__))
events_dir = os.path.join(script_dir, "spark-events")
master_url = "spark://localhost:7077"

# check if running in container
is_container = os.path.exists("/opt/spark")
if is_container:
    events_dir = "/tmp/spark-events"
    master_url = "spark://spark-master:7077"
else:
    # When running locally, PySpark doesn't load project's spark-defaults.xml
    # So we need to explicitly set event log config
    os.makedirs(events_dir, exist_ok=True)

conf = SparkConf().setAppName("Test Spark").setMaster(master_url)

# Only set event log config when running locally
# In container, spark-defaults.xml is automatically loaded from /opt/spark/conf
if not is_container:
    conf.set("spark.eventLog.enabled", "true") \
        .set("spark.eventLog.dir", f"file://{events_dir}")

sc = SparkContext(conf=conf)

spark = SparkSession.builder.enableHiveSupport().getOrCreate()

df = spark.createDataFrame([(1, "John"), (2, "Jane"), (3, "Jim")], ["id", "name"])
df.show()

spark.stop()
sc.stop()
print("Spark session stopped")
