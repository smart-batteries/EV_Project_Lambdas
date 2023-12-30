import Deterministic_Optimizer
import logging
import sys
import os
import psycopg2
import psycopg2.extras



class DeterministicDatasetBuilder():
    dataset = None
    logger = None
    conn = None
    
    def __init__(self, logger) -> None:
        self.logger = logger
        

    def getDataFromRunID(self, runID):
        self.dataset = Deterministic_Optimizer.Deterministic_Dataset()
        self.connectToDB()
        self.loadRunConfig(runID)
        self.loadPriceData(runID)        
        self.closeDBConnection()
        return self.dataset

    def connectToDB(self):
        self.logger.info("Connecting to DB")    
        #DB connection settings
        try:
            user = os.environ['USER_NAME']
            password = os.environ['PASSWORD']
            host = os.environ['RDS_HOST']
            dbname = os.environ['DB_NAME']
        except(Exception) as e:
            logging.error("Environment variables were not defined")
        
        try:
            self.conn = psycopg2.connect(host=host, user=user, password=password, dbname=dbname, connect_timeout=5)
            logging.info("Successfully connected to PostgreSQL.")            
        
        except (Exception, psycopg2.Error) as e:
            self.logger.error("ERROR: Failed to connect to PostgreSQL.")
            self.logger.error(e)
            sys.exit()

    def closeDBConnection(self):
        self.logger.info("Closing DB Connection")        
        self.conn.close()

    def loadRunConfig(self, runID):
        self.logger.info("Loading Run Config")        
        #Get run config info from the DB
        with self.conn.cursor() as cur:        
            try:
                cur.callproc("get_run_config_f", (runID,)) 

                result = cur.fetchall() 

                if(result == None):
                        self.logger.error("Error - no results returned from query")

                i = 0
                for row in result:
                    i += 1

                    if i >= 2:
                        self.logger.error("Error, multiple result rows returned - run is invalid")
                        sys.exit() #TODO Correct way to abort run and preserve the lamda for other, correct runs?


                    self.dataset.periodsUntilDeadline = row[0]
                    self.dataset.periodsOfChargeRequired = row[1]

                                                              
                
                                
            except (Exception, psycopg2.Error) as e:
                self.logger.error("ERROR: Failed to get run config data from database using run ID " + runID)
                self.logger.error(e)
                sys.exit() #TODO Correct way to abort run and preserve the lamda for other, correct runs?
    
    def loadPriceData(self, runID):
        self.logger.info("Loading Prices")            
        with self.conn.cursor() as cur:        
            try:
                self.dataset.prices = []
                # This was done as a stored procedure, rather than a hard coded query, to reduce DB-code coupling. 
                # Doing it this way lets the DB programmer change the underlying tables in the DB at will, so long as they update the stored procedure to match the changes they make to the tables.
                
                cur.callproc("get_run_data_f", (runID,)) 
                prev_period_number = -1
                for row in cur.fetchall():
                    if(prev_period_number == (row[1] - 1) or prev_period_number == -1 ):
                        self.dataset.prices.append(float(row[0]))
                        prev_period_number = row[1]
                    else:
                        self.logger.error("Error, periods are not consecutive, data is missing")
                        sys.exit() #TODO Correct way to abort run and preserve the lamda for other, correct runs?
                
                                
            except (Exception, psycopg2.Error) as e:
                self.logger.error("ERROR: Failed to get deterministic future price data from database using run ID " + runID)
                self.logger.error(e)
                sys.exit()




class DeterministicSolutionSaver():
    solution = None
    logger = None
    conn = None
    
    def __init__(self, logger) -> None:
        self.logger = logger
        psycopg2.extras.register_uuid()
        

    def saveSolutionForRunID(self, solution, runID):
        self.solution = solution
        self.runID = runID
        self.connectToDB()
        self.saveSolveMetadata()
        self.saveModelDecisions()
        self.closeDBConnection()        

    def connectToDB(self):
        self.logger.info("Connecting to DB")    
        #DB connection settings
        user = os.environ['USER_NAME']
        password = os.environ['PASSWORD']
        host = os.environ['RDS_HOST']
        dbname = os.environ['DB_NAME']
        
        try:
            self.conn = psycopg2.connect(host=host, user=user, password=password, dbname=dbname, connect_timeout=5)
            logging.info("Successfully connected to PostgreSQL.")            
        
        except (Exception, psycopg2.Error) as e:
            self.logger.error("ERROR: Failed to connect to PostgreSQL.")
            self.logger.error(e)
            sys.exit()

    
    def saveSolveMetadata(self):
        self.logger.info("Saving Metadata")
        #Save the solve results: feasibility, objective function value                
        
        with self.conn.cursor() as cur:        
            try:
                
                cur.execute("CALL save_run_results(%s, %s, %s);", (self.runID, self.solution.feasibility, self.solution.objectiveValue))                                 
                self.conn.commit()
                                
            except (Exception, psycopg2.Error) as e:
                self.logger.error("ERROR: Failed to get save the solve's metadata using run ID " + self.runID)
                self.logger.error(e)
                sys.exit()

    def saveModelDecisions(self):
        self.logger.info("Saving Decisions")
        #Save the decision variables
        with self.conn.cursor() as cur:        
            try:
                #create a list of tuples for insertion
                chargeDecisionsToInsert = []
                i = 1
                for chargeDecision in self.solution.decisions:
                    chargeDecisionsToInsert.append(chargeDecision)
                    i = i + 1

                cur.executemany("CALL save_run_decision(%s, %s, %s);", chargeDecisionsToInsert)                 
                self.conn.commit()
                                
            except (Exception, psycopg2.Error) as e:
                self.logger.error("ERROR: Failed to save the charing decisions using run ID " + self.runID)
                self.logger.error(e)
                sys.exit()



    def closeDBConnection(self):
        self.logger.info("Closing DB Connection")        
        self.conn.close()

    
