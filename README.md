# Smart battery charging

Charge your electric batteries at lowest cost.

From anywhere in New Zealand, just send in your charging info: location, kW, kWh, when to start charging, and when it needs to be ready by. We have a deterministic optimisation model that uses wholesale electricity price forecasts to work out at what times your device should charge.

Wholesale electricity prices can vary a lot. This way, you can be fully charged at lowest cost and least environmental impact.

Use-cases could include:
* Residential: electric vehicles.
* Commercial & industrial: grid battery storage.

## How to use the software

Set up the software by following the instructions in the “How to set up the software” section.

Once you’ve set it up:

1. Request the model to run.
* The request is sent to the model.
* The model solves the optimisation problem and generates the charging schedule for your device.
2. Request for the charging schedule.
* The software returns the charging schedule for the device.

## Architecture 

_diagram_

The software has two pipelines.

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




# How the software works

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

1. The user calls the software’s API, to request the model to run.
* Extract input data from their API call, and transform it so it’s in a usable format for the model.
* Extract the price forecasts relevant to the request.
2. Pass the transformed input data & price forecasts to the model.
3. The model solves the optimisation problem and saves its output.

4. The user calls the software’s API, to retrieve their charging schedule.
5. Return the charging schedule to the user.

## Database schema

_ERDs_




# How to set up the software

## Cloud account & remote repo

First, you’ll need to create an AWS account. The software should fit into their [free tier](aws.amazon.com/free), although we can't guarantee it won't cost cost you anything.

Then clone the repository into your home directory.
<pre>
git clone https://github.com/smart-batteries/EV_Project_Lambdas.git
cd EV_Project_Lambdas
</pre>

## WITS API

The price forecasts come from the New Zealand Electricity Authority’s WITS API.

**Steps:**

1. Create a [WITS developer account](developer.electricityinfo.co.nz/WITS).
2. Create an app.
* The redirect URI doesn’t matter, you can use any URL.
* Activate the Pricing_API_Application_Registration.
* Save the WITS client id and secret.

_Background info:_

* _About the [New Zealand Electricity Authority](ea.govt.nz)._
* _[Why we use their WITS API, not their EMI API](forum.emi.ea.govt.nz/thread/three-wholesale-market-price-apis-to-be-decommissioned-on-21-october-2022)._
* _Documentation for the [Market Prices catalogue](developer.electricityinfo.co.nz/WITS/documentation/market-prices)._

## Amazon Web Services

The software consists of:
* Docker images to process data; these will be hosted on AWS Lambda.
* a database to store data; this will be hosted on an AWS RDS PostgreSQL instance.

**Steps:**

1. Create an [AWS account](aws.amazon.com).
*  Follow the best practises, such as: creating an admin user separate to the root user; setting up MFA for each user.
2. [Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions) the AWS CLI.
* You can verify installation by running: ```aws --version```
3. For a designated IAM user, grant it programmatic access, so it can access AWS API-based methods via the CLI. In the console, go to the IAM service > 'Users' > find the user > 'Security credentials' section > 'Access keys' section > 'Create access key' button. Save the AWS access key id and secret.
* Store private information security, such as in a password manager.
4. In your local terminal, run ```aws configure``` and enter your information.
* Enter your user's AWS access key id and secret.
* Enter the AWS region you'll use; for example, "eu-north-1". Keep in mind, different regions having different pricing tiers and different schedules for rolling out new tools. "eu-north-1" and "us-east-1" are good defaults. Avoid Sao Paulo.
* Set the default output format to ```json```.

## Infrastructure as Code

We’ll use Terraform for IaC, to easily set up resources on AWS.

First, we'll set up these AWS resources: 
* ECR repos
* CloudWatch log groups

**Steps:**

1. Install [Terraform](https://developer.hashicorp.com/terraform/install).
* You may need to add the Terraform executable to your system's global path.
* You can verify installation by running: ```terraform --version```
2. Edit the ```EV_Project_Lambdas/terraform/first/variables.tf``` doc with the AWS region you'll use; for example, "eu-north-1".
3. Change to the ```EV_Project_Lambdas/terraform/first``` directory and run:
<pre>
terraform init
terraform apply --auto-approve
</pre>

At this point, you should have empty repos on ECR and empty log groups on CloudWatch.

## Populate ECR repos

Now, you have empty repos on [ECR](aws.amazon.com/ecr/), which need to be populated by the Docker images.

If you've forked this repo to your own GitHub repo, you can do this from there:
1. Add your AWS CLI access key id, access key secret and region to GitHub secrets. They should be named AWS_ACCESS_KEY_ID, AWS_ACCESS_KEY_SECRET and AWS_REGION respectively.
2. Manually dispatch the ```.github/workflows/deploy_functions.yml``` workflow.

Alternatively, you can do it manually from your local terminal:
1. If you haven't already, [install Docker](https://docs.docker.com/engine/install/).
* Follow the best practises, such as: creating a user to add to the ```docker``` group.
* Verify installation by running: ```docker --version```
2. Switch to your Docker user. Use the ```aws ecr get-login-password``` command to authenticate it to ECR, following [these instructions](https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html).
3. Push your Docker images, following [these instructions](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html). That means, for __each__ image:
* Change to its directory. For example, if you're starting with the PRSS image: ```EV_Project_Lambdas/images/prss```
* * Don't forget this step or you'll build the wrong image under the wrong name, which will end up being confusing.
* Build the image, for example: ```docker build --platform linux/amd64 -t prss:test .```
* * Don't forget the final ```.``` at the end of the command
* Tag the image, for example: ```docker tag prss:test <your-aws-account>.dkr.ecr.<your-aws-region>.amazonaws.com/prss:latest```
* Deploy the image, for example: ```docker push <your-aws-account>.dkr.ecr.<your-aws-region>.amazonaws.com/prss:latest```
* * If it's been some time since you authenticated, you may need to re-authenticate by running the same ```aws ecr get-login-password``` command.
* Remove the tagged image, for example: docker rmi 133433735071.dkr.ecr.eu-north-1.amazonaws.com/prss:latest

At this point, each of your ECR repos should have its corresponding Docker image.

## More IaC

Now that the ECR repos are ready, set up the rest of the AWS resources:
 
* Lambda functions
* PostgreSQL on RDS
* IAM execution roles
* VPC, subnets and security groups
* EventBridge schedules
* SQS queue
* HTTP API on API Gateway
* State machine on Step Functions

**Steps:**

1. Edit the ```EV_Project_Lambdas/terraform/second/variables.tf``` doc.
* Use __the same__ AWS region as you did in the ```EV_Project_Lambdas/terraform/first/variables.tf``` doc.
* Add the IP address of your home network (or wherever you want to connect to your database from).
* Create a username and password to log in to your database.
* Add the client id and secret from your WITS developer account.
3. Change to the ```EV_Project_Lambdas/terraform/second``` directory and run:
<pre>
terraform init
terraform apply --auto-approve
</pre>

At this point, you should have all the AWS resources you need.

## Set up database

Your PostgreSQL instance is currently empty. You need to add the tables and stored procedures.

**Steps:**

1. 
_create tables_
_create Stored procedures_
