# Hive Metastore Configuration Guide

This guide explains how to configure and change the Hive Metastore database for your local Spark setup.

## Overview

The Hive Metastore uses PostgreSQL by default. This document covers how to change the database configuration to use different database systems.

## Default Configuration

By default, the setup uses:
- **Database**: PostgreSQL
- **Port**: 5434 (mapped from container port 5432)
- **Database Name**: `metastore_db`
- **Username**: `hive`
- **Password**: `password`

## Changing the Metastore Database

### Step 1: Add Database Service (if using a new database)

Add your database service to `docker-compose.yml`. Example for MySQL:

```yaml
mysql:
  image: mysql:8.0
  ports:
    - "3306:3306"
  environment:
    - MYSQL_ROOT_PASSWORD=rootpassword
    - MYSQL_DATABASE=metastore_db
    - MYSQL_USER=hive
    - MYSQL_PASSWORD=password
  networks:
    - spark-network
  volumes:
    - mysql-data:/var/lib/mysql

volumes:
  mysql-data:
```

### Step 2: Update Metastore Service

Edit the `metastore` service in `docker-compose.yml`:

```yaml
metastore:
  image: apache/hive:4.0.0
  ports:
    - "9083:9083"
  environment:
    - SERVICE_NAME=metastore
    - DB_DRIVER=mysql  # Change to: postgres, mysql, oracle, etc.
    - SERVICE_OPTS=-Djavax.jdo.option.ConnectionDriverName=com.mysql.cj.jdbc.Driver \
      -Djavax.jdo.option.ConnectionURL=jdbc:mysql://mysql:3306/metastore_db \
      -Djavax.jdo.option.ConnectionUserName=hive \
      -Djavax.jdo.option.ConnectionPassword=password
  depends_on:
    - mysql  # Update dependency if using new database
  volumes:
    - warehouse:/opt/hive/warehouse
    - ./jars/mysql-connector-java-8.0.33.jar:/opt/hive/lib/mysql.jar
```

**Key parameters:**
- `DB_DRIVER`: Database type (postgres, mysql, oracle, derby, etc.)
- `ConnectionDriverName`: JDBC driver class name
- `ConnectionURL`: JDBC connection string
- `ConnectionUserName` / `ConnectionPassword`: Database credentials

### Step 3: Add JDBC Driver

1. Download the appropriate JDBC driver for your database
2. Place it in the `jars/` directory
3. Mount it in the `metastore` service volumes

**Common JDBC Drivers:**
- MySQL: `mysql-connector-java-8.0.33.jar`
- PostgreSQL: `postgresql-42.7.8.jar` (already included)
- Oracle: `ojdbc8.jar`

### Step 4: Initialize Schema and Restart

After making changes, restart services and initialize the schema:

```bash
docker-compose down
docker-compose up -d
docker-compose exec metastore /opt/hive/bin/schematool -dbType mysql -initSchema
```

Replace `mysql` with your database type (`postgres`, `mysql`, `oracle`, `derby`, `mssql`).

**Other schema operations:**
- Upgrade: `-upgradeSchema`
- Validate: `-validate`
- Show version: `-info`

## Database-Specific Examples

### MySQL

```yaml
# Connection URL format
jdbc:mysql://mysql:3306/metastore_db

# Driver class
com.mysql.cj.jdbc.Driver
```

### Oracle

```yaml
# Connection URL format
jdbc:oracle:thin:@oracle:1521:XE

# Driver class
oracle.jdbc.driver.OracleDriver
```

## Troubleshooting

**Verify services are running:**
```bash
docker-compose ps
docker-compose logs metastore
```

**Common issues:**
- **"Table already exists"**: Use `-upgradeSchema` instead of `-initSchema`
- **"Driver not found"**: Verify JDBC driver is in `jars/` and mounted in volumes
- **"Connection refused"**: Check database service is running and network connectivity
- **Test database connection**: `docker-compose exec postgres psql -U hive -d metastore_db`

## Best Practices

1. **Backup before changes**: Always backup your metastore database before making changes
2. **Test in isolation**: Test database changes in a separate environment first
3. **Use volumes**: Ensure database data is persisted using Docker volumes
4. **Version compatibility**: Ensure JDBC driver version is compatible with your database version
5. **Schema versioning**: Keep track of schema versions when upgrading

## Additional Resources

- [Hive Metastore Documentation](https://cwiki.apache.org/confluence/display/Hive/Hive+Metastore+Administration)
- [Hive Schema Tool Reference](https://cwiki.apache.org/confluence/display/Hive/Hive+Schema+Tool)

