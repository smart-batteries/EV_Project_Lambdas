from mip import *
import random

import os
import psycopg2
import logging
import sys
import json
import unittest

# create logger object
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Lambda Starting")    
    
    ### Establish a connection to the database ###
    conn = connectToDB()    

    ### Load the run ID from the lambda trigger ###    
    logger.info("Reading Request Data")
    runRequest = json.loads(event['Records'][0]['body'])
    runID = runRequest[0]["RunID"]

    ### Load the run data ###
    periodsUntilDeadline, periodsOfChargeRequired = loadRunConfig(conn, runID)    
    prices = loadPriceData(conn, runID)    

    validateRunData(periodsUntilDeadline, periodsOfChargeRequired, prices)    
  
    model, chargeDecisions = formulateModel(periodsUntilDeadline, periodsOfChargeRequired, prices)   

    logger.info("Optimizing Model")
    model_result = model.optimize(max_seconds=60)    
        

    ### Save the results to the DB ###   
    saveSolveMetadata(conn, runID, model_result)
        
    saveModelDecisions(conn, runID, chargeDecisions)
    
    closeDBConnection(conn)

def connectToDB():
    logger.info("Connecting to DB")    
    #DB connection settings
    user = os.environ['USER_NAME']
    password = os.environ['PASSWORD']
    host = os.environ['RDS_HOST']
    dbname = os.environ['DB_NAME']
    
    try:
        conn = psycopg2.connect(host=host, user=user, password=password, dbname=dbname, connect_timeout=5)
        logging.info("Successfully connected to PostgreSQL.")
        return conn
    
    except (Exception, psycopg2.Error) as e:
        logger.error("ERROR: Failed to connect to PostgreSQL.")
        logger.error(e)
        sys.exit()
  
def loadRunConfig(conn, runID):
    logger.info("Loading Run Config")        
    #Get run config info from the DB
    with conn.cursor() as cur:        
        try:
            cur.execute("CALL get_run_config(%s);", (runID)) 

            row = cur.fetch()
            periodsUntilDeadline = row["periods_until_deadline"]
            periodsOfChargeRequired = row["periods_of_charge_required"]
            return (periodsUntilDeadline, periodsOfChargeRequired)

                            
        except (Exception, psycopg2.Error) as e:
            logger.error("ERROR: Failed to get deterministic future price data from database.")
            logger.error(e)
            sys.exit()

def loadPriceData(conn, runID):
    logger.info("Loading Prices")            
    with conn.cursor() as cur:        
        try:
            prices = []
            # This was done as a stored procedure, rather than a hard coded query, to reduce DB-code coupling. 
            # Doing it this way lets the DB programmer change the underlying tables in the DB at will, so long as they update the stored procedure to match the changes they make to the tables.
            
            cur.execute("CALL getPriceData(%s);", (runID)) 

            for row in cur.fetchall():
                prices.append[row]
            return prices
                            
        except (Exception, psycopg2.Error) as e:
            logger.error("ERROR: Failed to get deterministic future price data from database.")
            logger.error(e)
            sys.exit()

def validateRunData(periodsUntilDeadline, periodsOfChargeRequired, prices):
    logger.info("Validating Dataset")
    #Assert some conditions about the run data that must be true for the solve to work - if they are not true, it will throw an error
    assert periodsUntilDeadline >= 0, "periodsUntilDeadline should be a position int"
    assert periodsOfChargeRequired >= 0, "periodsOfChargeRequired should be a position int"
    assert prices.__len__ == periodsUntilDeadline, "Error, price data provided did not match run config"
    assert periodsUntilDeadline >= periodsOfChargeRequired, "Error, the car cannot be charged in the time remaining"

def formulateModel(periodsUntilDeadline, periodsOfChargeRequired, prices):
    logger.info("Formulating Model")
    ### Use the data to run the model ###
    model = mip.Model(sense=MAXIMIZE, solver_name=CBC)

    chargeDecisions = [model.add_var(var_type=BINARY) for i in range(periodsUntilDeadline)]

    #constraint to enforce charging - todo relax it with a penalty variable
    model += xsum(chargeDecisions[i] for i in range(periodsUntilDeadline)) >= periodsOfChargeRequired

    #define objective
    model.objective = minimize(xsum(prices[i]*chargeDecisions[i] for i in range(periodsUntilDeadline)))

    #optimal solutions only
    model.max_gap = 0.00

    #Silence the CBC solver log output
    model.verbose = 0

    return model, chargeDecisions

def saveSolveMetadata(conn, runID, model_result):
    logger.info("Saving Metadata")
    #Save the solve results: feasibility, objective function value
    with conn.cursor() as cur:        
        try:
            
            cur.execute("CALL save_run_results(%s, %s, %s);", (runID, model_result.toString(), model_result.objective_value))                                 
                            
        except (Exception, psycopg2.Error) as e:
            logger.error("ERROR: Failed to get deterministic future price data from database.")
            logger.error(e)
            sys.exit()

def saveModelDecisions(conn, runID, chargeDecisions):
    logger.info("Saving Decisions")
    #Save the decision variables
    with conn.cursor() as cur:        
        try:
            #create a list of tuples for insertion
            chargeDecisionsToInsert = []
            i = 1
            for chargeDecision in chargeDecisions:
                chargeDecisionsToInsert.append((runID, i, chargeDecision.x))
                i = i + 1

            cur.executemany("CALL save_run_decision(%s, %s, %s);", chargeDecisionsToInsert)                 
                            
        except (Exception, psycopg2.Error) as e:
            logger.error("ERROR: Failed to get deterministic future price data from database.")
            logger.error(e)
            sys.exit()

def closeDBConnection(conn):
    logger.info("Closing DB Connection")
    conn.commit()
    conn.close()
  

print("DB Code is ready to go")

"""
###
TODO:
- Create the below stored procedures:
    - get_run_config
    - get_run_data
    - save_run_results
    - save_run_decision

- Define the implied tables that they refer to:
    - optimisation_problem_prices
    - optimisation_problems (solve problem definitions)
    - optimization_runs (solve executions)
    - optimization_run_decisions (What the sovler said the car should do)
    - time_periods (this table will allow us to join up optmization time periods (1,2 and so on) with 30 minute time windows in the EMI data)

- Put some dummy data into the tables

- Test that a run works and saves data out
    - Figure out how to upload this image to AW: (credentials from Isabelle (done), aws command line to push the docker image into ECR
    - Set up the associated env variables for the DB connection (possibly in the Dockerfile?)
    - Link that docker image to a lambda that can be triggered manually
    - Trigger the lambda and check if the decisions are saved out

- Make a process to automatically create optimisation problems out of the EMI data and user request information

- Create a query to return the results of an optimisation in terms of actual times of day, for visualisation
###

Stored procedure code:

#Get Run Config Information

CREATE OR REPLACE PROCEDURE get_run_config(
    v_run_id CHAR(32), 
    INOUT _result_one refcursor = 'rs_resultone'
) 
AS $$
BEGIN
	open _result_one for 
    SELECT  optimization_problems.periods_until_deadline, optimization_problems.periods_of_charge_required
    FROM optimization_problems    
    INNER JOIN optimization_runs ON optimization_runs.optimization_problem_id = optimization_problems.optimization_problem_id
    WHERE optimization_runs.run_id = v_run_id;	
	
END;
$$
LANGUAGE PLPGSQL;


#Get Price Data
CREATE OR REPLACE PROCEDURE get_run_data(
    v_run_id CHAR(32), 
    INOUT _result_one refcursor = 'rs_resultone'
) 
AS $$
BEGIN
	open _result_one for 
    SELECT  price
    FROM optimisation_problem_prices
    INNER JOIN optimization_problems ON optimization_problems.optimization_problem_id = optimisation_problem_prices.optimization_problem_id
    INNER JOIN optimization_runs ON optimization_runs.optimization_problem_id = optimization_problems.optimization_problem_id
    WHERE optimization_runs.run_id = v_run_id;	
	
END;
$$
LANGUAGE PLPGSQL;





#Save run metadata
CREATE OR REPLACE PROCEDURE save_run_results(
    v_run_id CHAR(32),
	v_feasibility_status varchar,
	v_objective_value float
) 
AS $$
BEGIN
	-- Update the run record
	update optimization_runs set feasibility_status = v_feasibility_status, objective_value = v_objective_value, run_status = "COMPLETE"
	WHERE optimization_runs.run_id = v_run_id;		
	
END;
$$
LANGUAGE PLPGSQL;


#Save run decision variables
CREATE OR REPLACE PROCEDURE save_run_decision(
    v_run_id CHAR(32),
    v_period_id INT,
    v_decision_value FLOAT
) 
AS $$
BEGIN
	INSERT into optimization_run_decisions (run_id, period_id, decision_value) values (v_run_id, v_period_id, v_decision_value);
	
END;
$$
LANGUAGE PLPGSQL;

"""