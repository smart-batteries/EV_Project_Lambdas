from mip import *
import logging
import uuid

import PostgresDBInteraction

class Deterministic_Model:

    def __init__(self, logger) -> None:
        self.logger = logger
        self.CBCModel = None
        self.chargeDecisions = None
        self.modelResult = None
        self.dataset = None
        self.solution = None

    def loadSolveAndSave(self, runID):        
        try:
            self.loadDataset(runID)
            self.formulate()
            self.optimize()
            self.generateSolution(runID)
            self.saveSolution(runID)            
        except(Exception) as e:
            raise
        

    def loadDataset(self, runID):
        builder = PostgresDBInteraction.DeterministicDatasetBuilder(self.logger)
        self.dataset = builder.getDataFromRunID(runID)
        

    def formulate(self):
        logger.info("Formulating Model")
        ### Use the data to run the model ###
        self.CBCModel = mip.Model(sense=MAXIMIZE, solver_name=CBC)

        self.chargeDecisions = [self.CBCModel.add_var(var_type=BINARY) for i in range(self.dataset.periodsUntilDeadline)]
        
        #constraint to enforce charging - todo relax it with a penalty variable
        self.CBCModel += xsum(self.chargeDecisions[i] for i in range(self.dataset.periodsUntilDeadline)) >= self.dataset.periodsOfChargeRequired

        #define objective
        self.CBCModel.objective = minimize(xsum(self.dataset.prices[i]*self.chargeDecisions[i] for i in range(self.dataset.periodsUntilDeadline)))

        #optimal solutions only
        self.CBCModel.max_gap = 0.00

        #Silence the CBC solver log output
        self.CBCModel.verbose = 0        
    
    def optimize(self):
        self.modelResult = self.CBCModel.optimize(max_seconds=60)

    def generateSolution(self, runID):
        self.solution = Deterministic_Solution(self.modelResult, self.CBCModel, self.chargeDecisions, runID, self.dataset.priceIDs)        
    
    def saveSolution(self, runID):
        PostgresDBInteraction.DeterministicSolutionSaver(self.logger).saveSolutionForRunID(self.solution, runID)



class Deterministic_Solution:    

    
        
    def __init__(self, modelResult, Model_CBC, chargeDecisions, runID, priceIDs):        
        try:
            self.feasibility = None
            self.objectiveValue = None       
            self.decisions = []
            logger.info(modelResult)
            logger.info(Model_CBC)
            logger.info(chargeDecisions)            
            
            i = 1
            for chargeDecision in chargeDecisions:
                self.decisions.append(( uuid.UUID(runID), i, chargeDecision.x >= 0.5, priceIDs[i-1]))
                i = i + 1        

            if(modelResult == OptimizationStatus.OPTIMAL):
                self.feasibility = 0
            elif(modelResult == OptimizationStatus.INFEASIBLE):
                self.feasibility = 1
            elif(modelResult == OptimizationStatus.UNBOUNDED):
                self.feasibility = 2
            elif(modelResult == OptimizationStatus.FEASIBLE):
                self.feasibility = 3
            elif(modelResult == OptimizationStatus.INT_INFEASIBLE):
                self.feasibility = 4
            elif(modelResult == OptimizationStatus.NO_SOLUTION_FOUND):
                self.feasibility = 5
            elif(modelResult == OptimizationStatus.LOADED):
                self.feasibility = 6
            elif(modelResult == OptimizationStatus.CUTOFF):
                self.feasibility = 7
            else:
                self.feasibility = -1

            
            self.objectiveValue = Model_CBC.objective_value  
        except(Exception) as e:
            logger.error(e, "Issue with generating a aloution object from solver data")
            raise
    


class Deterministic_Dataset:    
    
    def __init__(self):
        self.periodsUntilDeadline = None
        self.periodsOfChargeRequired = None
        self.prices = None        
        self.priceIDs = None

    def validate(self):
        logger.info("Validating Dataset")
        #Assert some conditions about the run data that must be true for the solve to work - if they are not true, it will throw an error
        assert self.periodsUntilDeadline >= 0, "periodsUntilDeadline should be a position int"
        assert self.periodsOfChargeRequired >= 0, "periodsOfChargeRequired should be a position int"
        assert self.prices.__len__ == self.periodsUntilDeadline, "Error, price data provided did not match run config"
        assert self.periodsUntilDeadline >= self.periodsOfChargeRequired, "Error, the car cannot be charged in the time remaining"

    

        
        




