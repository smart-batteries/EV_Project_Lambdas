import os
import logging
import sys
import psycopg2
import json
from datetime import datetime

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
    logging.info(f"Successfully connected to {dbname} database at {host}.")
except (Exception, psycopg2.Error) as e:
    logger.error("ERROR: Failed to connect to PostgreSQL.")
    logger.error(e)
    sys.exit()


with conn.cursor() as cur:    

    # Create staging table
    try:
        cur.execute("CALL merge_create_stage();")
        conn.commit()
        logger.info("Successfully created staging table in database.")

    except (Exception, psycopg2.Error) as e:
        logger.error("ERROR: Failed to create staging table in database.")
        logger.error(e)
        sys.exit()


def lambda_handler(event, context):
    
    with conn.cursor() as cur:
        
        for record in event['Records']:
            
            # Retrieve price forecasts from the message
            try:
                price_forecasts = json.loads(record['body'])
                time_of_forecast = price_forecasts[0]["lastRunTime"]
                logger.info(f"Successfully extracted price data from queue, for time of forecast: {time_of_forecast}.")

            except Exception as e:
                logger.error("ERROR: Failed to extract price data from queue.")
                logger.error(e)
                sys.exit()
                
            # Add price forecasts to the staging table
            try:
                for forecast in price_forecasts:
                    cur.execute(
                        "CALL merge_insert_stage(%s::character varying, %s, %s::smallint, %s, %s, %s::character varying);",
                        (
                            forecast['node'],
                            datetime.strptime(forecast['tradingDateTime'][:19], '%Y-%m-%dT%H:%M:%S'),
                            forecast['tradingPeriod'],
                            forecast['price'],
                            datetime.strptime(forecast['lastRunTime'][:19], '%Y-%m-%dT%H:%M:%S'),
                            forecast['schedule']
                        )
                    )
                    conn.commit()
                    logger.info(f"Successfully inserted price data into staging table, for forecast time: {time_of_forecast}.")
                
            except (Exception, psycopg2.Error) as e:
                logger.error("ERROR: Failed to insert price data into staging table.")
                logger.error(e)
                sys.exit()
                
            # Merge price data into primary table
            try:
                cur.execute("CALL merge_update_forecasts();")
                conn.commit()
                cur.execute("CALL merge_insert_forecasts();")
                conn.commit()
                logger.info(f"Successfully merged price data into primary table, for time of forecast: {time_of_forecast}.")
            
            except (Exception, psycopg2.Error) as e:
                logger.error(f"ERROR: Failed to merge price data into primary table, for time of forecast: {time_of_forecast}.")
                logger.error(e)
                sys.exit()