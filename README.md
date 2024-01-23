# Smart battery charging

Charge your electric batteries at lowest cost.

From anywhere in New Zealand, just send in your charging info: location, kW, kWh, when to start charging, and when it needs to be ready by. We have a deterministic optimisation model that uses wholesale electricity price forecasts to work out at what times your device should charge.

Wholesale electricity prices can vary a lot. This way, you can be fully charged at lowest cost and least environmental impact.

Use-cases could include:
* Residential: electric vehicles.
* Commercial & industrial: grid battery storage.

## How to use the tool

Set up the tool by following the instructions in the “How to set up the tool” section.

Once you’ve set it up:

1. Request the model to run.
* The request is sent to the model.
* The model solves the optimisation problem and generates the charging schedule for your device.
2. Request for the charging schedule.
* The tool returns the charging schedule for the device.

## Architecture 

_diagram_

The tool has two pipelines.

The first:

* Extracts price forecasts from the New Zealand Electricity Authority’s [WITS API](developer.electricityinfo.co.nz/WITS)
* Buffers the data with [AWS SQS](aws.amazon.com/sqs).
* Loads the data into a [PostgreSQL](postgresql.org) instance on [AWS RDS](aws.amazon.com/rds).

The second:
* Receives user requests and serves responses with [AWS API Gateway](aws.amazon.com/api-gateway).
* Orchestrates the response with [AWS Step Functions](aws.amazon.com/step-functions).

Overall:
* Process with [Docker](docker.com) images hosted on [AWS Lambda](aws.amazon.com/lambda).
* Create AWS resources with [Terraform](https://www.terraform.io/).

## Example

_this bit_

# How the tool works

## Solver model

_Josh_

## ETL pipelines

There are two pipelines:

Forecast pipeline

1. Every 30 min: Extract short-term price forecasts from the WITS API.
2. Every 2 hours: Extract long-term price forecasts from the WITS API.
3. Forecasts are merged into the database:
  * new data is added;
  * outdated data is overwritten with the latest forecasts.
4. Historical forecasts (>1 month in the past) are purged from the database.

User request pipeline

1. The user calls the tool’s API, to request the model to run.
* Extract input data from their API call, and transform it so it’s in a usable format for the model.
* Extract the price forecasts relevant to the request.
2. Pass the transformed input data & price forecasts to the model.
3. The model solves the optimisation problem and saves its output.

4. The user calls the tool’s API, to retrieve their charging schedule.
5. Return the charging schedule to the user.

## Database schema

_ERDs_

# How to set up the tool

## Cloud account & remote repo

First, you’ll need to create an AWS account. The tool should fit into their [free tier](aws.amazon.com/free), although we can't guarantee it won't cost cost you anything.

Then clone the repository into your home directory.
<pre>
git clone https://github.com/smart-batteries/EV_Project_Lambdas.git
cd EV_Project_Lambdas
</pre>

## WITS API

The price forecasts come from the New Zealand Electricity Authority’s WITS API.

Steps:

1. Create a [WITS developer account](developer.electricityinfo.co.nz/WITS).
2. Create an app.
* The redirect URI doesn’t matter, you can use any URL.
* Activate the Pricing_API_Application_Registration.
* Save the client ID and secret.

Background info:

* About the [New Zealand Electricity Authority](ea.govt.nz).
* [Why we use their WITS API, not their EMI API](forum.emi.ea.govt.nz/thread/three-wholesale-market-price-apis-to-be-decommissioned-on-21-october-2022).
* Documentation for the [Market Prices catalogue](developer.electricityinfo.co.nz/WITS/documentation/market-prices).

## Amazon Web Services

The tool consists of:
* Docker images to process data; these will be hosted on AWS Lambda.
* a database to store data; this will be hosted on an AWS RDS PostgreSQL instance.

Steps:

1. Create an [AWS account](aws.amazon.com).
* Follow the best practises, such as: creating an admin user separate to the root user; setting up MFA for each user.
2. Install and configure AWS CLI.

## Infrastructure as Code

We’ll use Terraform for IaC, to easily set up these resources on AWS:
 
* Lambda functions
* Postgres on RDS
* IAM execution roles
* VPC, subnets and security groups
* EventBridge schedules
* SQS queue
* API Gateway
* Step Function state machine
* CloudWatch log groups
* ECR repos

_run Terraform first_
_set the AWS region in variables.tf_

## Populate ECR repos

## More IaC

_Terraform second_
_set the AWS region in variables.tf, as well as WITS & RDS & IP info_

## Set up database

_create tables_
_create Stored procedures_
