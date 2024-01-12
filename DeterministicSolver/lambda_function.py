import sys

import Deterministic_Optimizer
import logging
import json
import unittest


# create logger object
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info(sys.version)

    logger.info("Lambda Starting")    

    ### Load the run ID from the lambda trigger ###    
    logger.info("Reading Request Data")    
    runID = event['RunID']    
    
    model = Deterministic_Optimizer.Deterministic_Model(logger)

    try:
        model.loadSolveAndSave(runID)
    except(Exception) as e:
        logger.error("An error occured, return from the lambda function handler to exit gracefully") 
        return   
    
    logger.info("Solve Ran And did not error")
   

print("DB Code is ready to go")

#build the container
#docker build --platform linux/amd64 -t docker-image:test .

#test the container, run it
#docker run -p 9000:8080 docker-image:test

# send it an event using windows powershell
#Invoke-WebRequest -Uri "http://localhost:9000/2015-03-31/functions/function/invocations" -Method Post -Body '{"RunID":"2efa0e58-2a2e-4242-913c-048b852609e0"}' -ContentType "application/json"

#send it an event on linux
#curl "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"RunID":"2efa0e58-2a2e-4242-913c-048b852609e0"}'

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