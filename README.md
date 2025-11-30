# Local Spark Setup with Docker

This project provides a complete local Spark development environment using Docker Compose. It includes Spark standalone cluster, Hive Metastore, Spark History Server, and Delta Lake built-in for ACID transactions and time travel capabilities.

## 📑 Table of Contents

- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
  - [Start the Spark Cluster](#1-start-the-spark-cluster)
  - [Verify Services are Running](#2-verify-services-are-running)
  - [Access Spark Master UI](#3-access-spark-master-ui)
- [Executing Spark Code](#-executing-spark-code)
- [Using Jupyter Notebooks](#-using-jupyter-notebooks)
- [Accessing Spark History Server](#-accessing-spark-history-server)
- [Using Delta Lake](#-using-delta-lake)
- [Changing Metastore Configuration](#️-changing-metastore-configuration)
- [Configuration Files](#-configuration-files)
- [Adding Custom JARs and Plugins](#-adding-custom-jars-and-plugins)
- [Stopping the Cluster](#-stopping-the-cluster)
- [Contributing](#-contributing)
- [Additional Resources](#-additional-resources)

## 🏗️ Architecture

The setup includes:
- **Spark Master** - Cluster manager (ports: 7077, 8080)
- **Spark Worker** - Worker node for executing tasks
- **Spark History Server** - UI for viewing completed Spark applications (port: 18080)
- **Jupyter Lab** - Interactive notebook environment for Spark development (port: 8888)
- **Delta Lake** - Built-in support for ACID transactions, time travel, and schema evolution (version 4.0.0)
- **Hive Metastore** - Metadata management service (port: 9083)
- **HiveServer2** - Hive JDBC/ODBC server (ports: 10000, 10002)
- **PostgreSQL** - Database for Hive Metastore (port: 5434)
- **LocalStack** - Local AWS S3 emulation (port: 4566)

## 📋 Prerequisites

- Docker and Docker Compose installed
- Python 3.x (for running PySpark scripts)
- PySpark installed locally: `pip install pyspark`

## 🚀 Getting Started

### 1. Start the Spark Cluster

Start all services using Docker Compose:

```bash
docker-compose up -d
```

This will start all services in detached mode. Wait a few moments for all services to initialize.

### 2. Verify Services are Running

Check the status of all containers:

```bash
docker-compose ps
```

You should see all services in "Up" status.

### 3. Access Spark Master UI

Open your browser and navigate to:
- **Spark Master UI**: http://localhost:8080

You should see the Spark cluster overview with worker nodes registered.

### 4. Enable Metastore State Persistence (Important!)

After the initial setup and first successful run, you should change `IS_RESUME` to `true` in `docker-compose.yml` to ensure metastore state is persisted across container restarts.

**In `docker-compose.yml`, update both services:**
- `metastore` service: Change `IS_RESUME=false` to `IS_RESUME=true` (line ~112)
- `hiveserver2` service: Change `IS_RESUME=false` to `IS_RESUME=true` (line ~97)

After making this change, restart the services:
```bash
docker-compose restart metastore hiveserver2
```

**Why?** Setting `IS_RESUME=false` initializes the metastore schema on first run. After initialization, setting it to `true` preserves your metastore state (tables, schemas, etc.) when containers restart, preventing data loss.

## 💻 Executing Spark Code

This section covers different ways to execute Spark code, whether through scripts or interactive shells.

### Running Spark Scripts

#### Option 1: Using PySpark with Local Installation

Run Spark scripts from your local machine that connect to the Docker Spark cluster:

```bash
python test_spark.py
```

The script should connect to `spark://localhost:7077` and execute on the cluster.

#### Option 2: Using Docker Container (Recommended)

Run a Spark script inside a container for proper event log finalization:

**Easy way using the helper script:**
```bash
./run_in_container.sh test_spark.py
```

The script accepts any Python file as an argument:
```bash
./run_in_container.sh your_script.py
```

**Or manually:**
```bash
docker-compose run --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  spark-master \
  spark-submit \
    --master spark://spark-master:7077 \
    --deploy-mode client \
    --conf spark.eventLog.enabled=true \
    --conf spark.eventLog.dir=file:///tmp/spark-events \
    /workspace/test_spark.py
```

**Why run in container?** When the driver runs in a container (same environment as workers), event logs are properly finalized and appear in the History Server. Running locally may result in incomplete event logs.

### Running Interactive Shells

#### Python Shell (pyspark)

**From local machine (if PySpark is installed):**
```bash
pyspark --master spark://localhost:7077
```

**From Docker container:**
```bash
docker-compose run --rm spark-master pyspark \
  --master spark://spark-master:7077 \
  --deploy-mode client
```

### Example Script

See `test_spark.py` for a basic example:

```python
from pyspark import SparkContext, SparkConf
from pyspark.sql import SparkSession

conf = SparkConf().setAppName("Test Spark").setMaster("spark://localhost:7077")
sc = SparkContext(conf=conf)

spark = SparkSession.builder.enableHiveSupport().getOrCreate()

df = spark.createDataFrame([(1, "John"), (2, "Jane"), (3, "Jim")], ["id", "name"])
df.show()

spark.stop()
```

## 📓 Using Jupyter Notebooks

Jupyter Lab is included in this setup, providing an interactive notebook environment for Spark development with full access to the Spark cluster.

### Accessing Jupyter Lab

1. **Start all services** (if not already running):
   ```bash
   docker-compose up -d
   ```

2. **Access Jupyter Lab**:
   Open your browser and navigate to:
   - **Jupyter Lab**: http://localhost:8888

   Jupyter Lab is configured to run without authentication for local development. The notebooks directory is mounted as a volume, so all notebooks are persisted on your host machine.

### Connecting to Spark from Jupyter

When working in Jupyter notebooks, configure Spark to connect to the cluster:

```python
from pyspark.sql import SparkSession
from pyspark import SparkConf

# Create Spark session
spark = SparkSession.builder.enableHiveSupport().getOrCreate()

# Verify connection
print(f"Spark version: {spark.version}")
print(f"Spark master: {spark.sparkContext.master}")
```

### Example Notebook

A sample notebook (`example_spark_connection.ipynb`) is included in the `notebooks/` directory demonstrating:
- Connecting to the Spark cluster
- Basic Spark operations
- Delta Lake integration

### Notebook Directory

- **Location**: `./notebooks/` (on your host machine)
- **Container path**: `/workspace/notebooks`
- All notebooks created in Jupyter are automatically saved to your local `notebooks/` directory

### Features

- **Full Spark Access**: Run PySpark code that executes on the Spark cluster
- **Delta Lake Support**: Delta Lake is pre-installed and ready to use
- **Event Logging**: All Spark jobs from notebooks are logged and visible in the History Server
- **Persistent Storage**: Notebooks are saved to your host machine
- **Shared Resources**: Access to the same warehouse, configuration, and event logs as other Spark applications

### Tips

- **Reuse Spark Session**: Create the Spark session once at the beginning of your notebook and reuse it throughout
- **Stop Session**: Call `spark.stop()` at the end of your notebook to free resources
- **View History**: After running Spark code in notebooks, check the History Server at http://localhost:18080 to see job details
- **Delta Tables**: Delta tables created in notebooks are stored in `/opt/hive/warehouse/` and accessible from other Spark applications

## 📊 Accessing Spark History Server

The Spark History Server provides a web UI to view completed Spark applications.

### Access the UI

Open your browser and navigate to:
- **Spark History Server**: http://localhost:18080

### Viewing Application Logs

1. Run a Spark application (script or shell)
2. After the application completes, refresh the History Server UI
3. Click on the application to view:
   - Job details
   - Stage information
   - Task execution timeline
   - Executor metrics

### Enabling Event Logging

Event logging is already enabled in `conf/spark-defaults.xml`:

```xml
<property>
    <name>spark.eventLog.enabled</name>
    <value>true</value>
</property>
<property>
    <name>spark.eventLog.dir</name>
    <value>/tmp/spark-events</value>
</property>
<property>
    <name>spark.history.fs.logDirectory</name>
    <value>/tmp/spark-events</value>
</property>
```

**Important**: The `spark-events` directory is mounted as a bind mount (not a Docker volume) so that both:
- Local Spark applications (running on your host machine)
- Containerized Spark applications (running in Docker)

can write event logs to the same location (`./spark-events/`), which the History Server can then read and display.

When running Spark scripts locally (like `test_spark.py`), the script automatically configures the event log directory to point to the shared `spark-events` folder.

## 🗄️ Using Delta Lake

Delta Lake is pre-configured and ready to use in this setup. Delta Lake provides ACID transactions, time travel, and schema evolution for your data lakes.

### Features Enabled

Delta Lake 4.0.0 is installed and configured via `conf/spark-defaults.xml`:
- **Delta Catalog** - Set as the default Spark catalog
- **Delta Spark Session Extension** - Automatically enabled for all Spark sessions

### Basic Usage

Delta Lake works automatically - no additional configuration needed:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Delta Example") \
    .enableHiveSupport() \
    .getOrCreate()

# Create a Delta table
df = spark.createDataFrame([(1, "Alice"), (2, "Bob")], ["id", "name"])
df.write.format("delta").save("/opt/hive/warehouse/delta_table")

# Read from Delta table
delta_df = spark.read.format("delta").load("/opt/hive/warehouse/delta_table")
delta_df.show()

# Time travel - read a specific version
df_v0 = spark.read.format("delta").option("versionAsOf", 0).load("/opt/hive/warehouse/delta_table")

# Time travel - read at a specific timestamp
df_timestamp = spark.read.format("delta").option("timestampAsOf", "2024-01-01").load("/opt/hive/warehouse/delta_table")
```

### Delta Lake Operations

**Create a Delta table:**
```python
df.write.format("delta").mode("overwrite").save("/opt/hive/warehouse/my_table")
```

**Update data:**
```python
from delta.tables import DeltaTable

delta_table = DeltaTable.forPath(spark, "/opt/hive/warehouse/my_table")
delta_table.update("id = 1", {"name": "'Updated Name'"})
```

**Merge operations:**
```python
delta_table.alias("target").merge(
    source_df.alias("source"),
    "target.id = source.id"
).whenMatchedUpdateAll().whenNotMatchedInsertAll().execute()
```

**Schema evolution:**
```python
# Delta Lake automatically handles schema evolution
df.write.format("delta").mode("append").option("mergeSchema", "true").save("/opt/hive/warehouse/my_table")
```

### Using with Hive Metastore

Delta tables can be registered in the Hive Metastore:

```python
# Save as Delta and register in Hive
df.write.format("delta").saveAsTable("my_delta_table")
```

### Additional Resources

- [Delta Lake Documentation](https://docs.delta.io/)
- [Delta Lake GitHub](https://github.com/delta-io/delta)

## 🗄️ Changing Metastore Configuration

The Hive Metastore uses PostgreSQL by default. To change the database configuration, see the detailed guide:

📖 **[Metastore Configuration Guide](METASTORE_CONFIG.md)**

The guide covers:
- Modifying docker-compose.yml
- Updating hive-site.xml
- Using different database services (MySQL, Oracle, etc.)
- Initializing and upgrading metastore schema
- Troubleshooting common issues

### Persisting Metastore State

**Important:** After the initial setup and first successful run, change `IS_RESUME` to `true` in `docker-compose.yml` to ensure metastore state is persisted across container restarts.

1. **Edit `docker-compose.yml`** and update both services:
   - `metastore` service: Change `IS_RESUME=false` to `IS_RESUME=true`
   - `hiveserver2` service: Change `IS_RESUME=false` to `IS_RESUME=true`

2. **Restart the services:**
   ```bash
   docker-compose restart metastore hiveserver2
   ```

**Understanding IS_RESUME:**
- `IS_RESUME=false`: Initializes the metastore schema on first run (required for initial setup)
- `IS_RESUME=true`: Preserves existing metastore state when containers restart (prevents data loss)

**When to change:**
- ✅ After successful first initialization
- ✅ When you want to preserve tables, schemas, and metadata across restarts
- ❌ Keep `false` only during initial setup or when you need to reset the metastore

## 🔧 Configuration Files

Configuration files are located in the `conf/` directory and are mounted into containers:

- `spark-defaults.xml` - Spark default configurations
- `hive-site.xml` - Hive Metastore configuration
- `core-site.xml` - Hadoop core configuration
- `hdfs-site.xml` - HDFS configuration

Changes to these files require restarting the services:

```bash
docker-compose restart
```

## 📦 Adding Custom JARs and Plugins

To use custom JARs or plugins in your Spark applications, you can add them to the `jars/` directory and configure Spark to load them.

### Step 1: Add JARs to the jars/ Directory

Place your custom JAR files in the `jars/` directory:

```bash
cp your-custom-library.jar jars/
```

### Step 2: JARs Directory is Already Mounted

The `jars/` directory is already mounted to `/opt/spark/jars/custom` in all Spark services (`spark-master`, `spark-worker`, and `spark-history-server`) in `docker-compose.yml`. No additional configuration needed!

If you need to verify or modify the mount, check the volumes section in `docker-compose.yml`:

```yaml
volumes:
  - ./spark-events:/tmp/spark-events
  - ./conf:/opt/spark/conf
  - ./jars:/opt/spark/jars/custom  # Already configured
  - warehouse:/opt/hive/warehouse
```

### Step 3: Configure Spark to Use Custom JARs

**Option A: Using spark-defaults.xml (Recommended)**

Add to `conf/spark-defaults.xml`:

```xml
<property>
    <name>spark.jars</name>
    <value>/opt/spark/jars/custom/*.jar</value>
</property>
```

Or specify individual JARs:

```xml
<property>
    <name>spark.jars</name>
    <value>/opt/spark/jars/custom/library1.jar,/opt/spark/jars/custom/library2.jar</value>
</property>
```

**Option B: Using spark-submit**

When submitting jobs, use the `--jars` option:

```bash
docker-compose run --rm spark-master spark-submit \
  --master spark://spark-master:7077 \
  --jars /opt/spark/jars/custom/your-library.jar \
  /workspace/your_script.py
```

**Option C: In Your Python Code**

```python
from pyspark import SparkContext, SparkConf

conf = SparkConf().setAppName("My App") \
    .setMaster("spark://localhost:7077") \
    .set("spark.jars", "/opt/spark/jars/custom/your-library.jar")

sc = SparkContext(conf=conf)
```

### Step 4: Restart Services

After adding JARs and updating configuration:

```bash
docker-compose restart
```

### Example: Adding a Custom Connector

1. Download the JAR (e.g., `mysql-connector-java-8.0.33.jar`)
2. Place it in `jars/`
3. Mount it in docker-compose.yml (as shown above)
4. Use it in your Spark code:

```python
spark = SparkSession.builder \
    .appName("MySQL Example") \
    .config("spark.jars", "/opt/spark/jars/custom/mysql-connector-java-8.0.33.jar") \
    .getOrCreate()

# Now you can use the connector
df = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:mysql://mysql-host:3306/dbname") \
    .option("dbtable", "table_name") \
    .load()
```

### Notes

- JARs in `jars/` are automatically available to all Spark services (master, worker, history-server)
- For driver-only JARs, use `spark.driver.extraClassPath` instead of `spark.jars`
- For executor-only JARs, use `spark.executor.extraClassPath`
- JARs are loaded at SparkContext initialization, so changes require restarting your application

## 🛑 Stopping the Cluster

Stop all services:

```bash
docker-compose down
```

To remove all volumes (including data):

```bash
docker-compose down -v
```

## 📚 Additional Resources

### Useful Commands

- View logs: `docker-compose logs -f [service-name]`
- Execute commands in container: `docker-compose exec [service-name] bash`
- Check Spark Master status: `curl http://localhost:8080`

### Ports Reference

- **7077** - Spark Master (cluster communication)
- **8080** - Spark Master Web UI
- **8888** - Jupyter Lab
- **18080** - Spark History Server
- **9083** - Hive Metastore
- **10000** - HiveServer2 (JDBC)
- **10002** - HiveServer2 (HTTP)
- **5434** - PostgreSQL
- **4566** - LocalStack (S3)

### Troubleshooting

1. **Services not starting**: Check logs with `docker-compose logs`
2. **Connection refused**: Ensure all services are up with `docker-compose ps`
3. **Metastore errors**: Verify database is running and schema is initialized
4. **Port conflicts**: Change port mappings in `docker-compose.yml` if ports are already in use
5. **History Server not showing logs**: 
   - Ensure the `spark-events` directory exists: `mkdir -p spark-events`
   - Restart the History Server: `docker-compose restart spark-history-server`
   - Verify event logging is enabled in your Spark application
   - Check that your Spark app writes to the shared `spark-events` directory (local apps should use the path relative to your project root)

## 🤝 Contributing

We welcome contributions to improve this project! Whether it's bug fixes, new features, documentation improvements, or suggestions, your input is valuable.

### How to Contribute

1. **Report Issues**: Found a bug or have a problem? Please [open an issue](../../issues/new) with:
   - A clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Docker version, etc.)

2. **Request Features**: Have an idea for a new feature or improvement?
   - [Open a feature request](../../issues/new?template=feature_request.md)
   - Describe the use case and benefits
   - Suggest how it might be implemented (if you have ideas)

3. **Improve Documentation**: 
   - Fix typos or clarify confusing sections
   - Add examples or use cases
   - Improve code comments

4. **Submit Code Changes**:
   - Fork the repository
   - Create a feature branch
   - Make your changes
   - Test thoroughly
   - Submit a pull request with a clear description

### Contribution Guidelines

- **Be respectful**: Maintain a friendly and inclusive environment
- **Be clear**: Write clear commit messages and PR descriptions
- **Test changes**: Ensure your changes work as expected
- **Follow style**: Maintain consistency with existing code style
- **Document**: Update README or relevant docs for new features

### Getting Help

- Check existing [issues](../../issues) to see if your question was already asked
- Review the documentation in the README and other markdown files
- Open a new issue if you need help or have questions

Thank you for contributing to this project! 🎉

## 📄 License

This project is for local development purposes.

