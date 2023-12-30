import os
import logging
import sys
import psycopg
import json

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
    conn = psycopg.connect(host=host, dbname=dbname, user=user, password=password, connect_timeout=10)
    logging.info("Successfully connected to PostgreSQL.")
except (Exception, psycopg.Error) as e:
    logger.error("ERROR: Failed to connect to PostgreSQL.")
    logger.error(e)
    sys.exit()


with conn.cursor() as cur:    

    # Create staging table
    try:
        cur.callproc("merge_create_stage")
        conn.commit()
        logger.info("Successfully created staging table in database.")

    except (Exception, psycopg.Error) as e:
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
                ######## in each WITS API call, all forecasts were made at the same... is this true of PRSL as well as PRSS?
                logger.info(f"Successfully extracted price data from queue, for time of forecast: {time_of_forecast}.")

            except Exception as e:
                logger.error("ERROR: Failed to extract price data from queue.")
                logger.error(e)
                sys.exit()
                
            # Add price forecasts to the staging table
            try:
                for forecast in price_forecasts:
                    cur.callproc(
                        "insert_stage",
                        (
                            forecast['tradingDateTime'],
                            forecast['tradingPeriod'],
                            forecast['node'],
                            forecast['price'],
                            forecast['lastRunTime'],
                            forecast['schedule']
                        )
                    )
                    conn.commit()
                logger.info(f"Successfully inserted price data into staging table, for forecast time: {time_of_forecast}.")
                
            except (Exception, psycopg.Error) as e:
                logger.error("ERROR: Failed to insert price data into staging table.")
                logger.error(e)
                sys.exit()
                
            # Merge price data into primary table
            try:
                cur.callproc("merge_update_forecasts")
                conn.commit()
                cur.callproc("merge_insert_forecasts")
                conn.commit()
                logger.info(f"Successfully merged price data into primary table, for time of forecast: {time_of_forecast}.")
            
            except (Exception, psycopg.Error) as e:
                logger.error(f"ERROR: Failed to merge price data into primary table, for time of forecast: {time_of_forecast}.")
                logger.error(e)
                sys.exit()