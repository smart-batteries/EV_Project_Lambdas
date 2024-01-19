import os
import logging
import sys
import psycopg2

# db connection settings
host = os.environ['RDS_HOST']
dbname = os.environ['DB_NAME']
user = os.environ['USER_NAME']
password = os.environ['PASSWORD']

# create logger object
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Establish a connection to the database
try:
    conn = psycopg2.connect(host=host, dbname=dbname, user=user, password=password, connect_timeout=10)
    logging.info("Successfully connected to PostgreSQL.")
except (Exception, psycopg2.Error) as e:
    logger.error("ERROR: Failed to connect to PostgreSQL.")
    logger.error(e)
    sys.exit()


def lambda_handler(event, context):
    
    with conn.cursor() as cur:
        
        # Remove outdated forecasts
        try:
            cur.callproc("purge_old_forecasts")
            conn.commit()
            logger.info(f"Successfully purged outdated price forecasts.")
                
        except (Exception, psycopg2.Error) as e:
            logger.error(f"ERROR: Failed to purge outdated price forecasts from price_forecasts table.")
            logger.error(e)
            sys.exit()