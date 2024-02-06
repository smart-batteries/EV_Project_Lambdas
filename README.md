# Smart battery charging

Charge your electric batteries at lowest cost.

From anywhere in New Zealand, just send in your charging info: location, kWh, kW, when to start charging, and when the battery needs to be ready by. We have a deterministic optimisation model that uses wholesale electricity price forecasts to work out at what times your device should charge.

Wholesale electricity prices can vary a lot. This way, you can be fully charged at lowest cost and least environmental impact.

Use-cases could include:
* Residential: electric vehicles.
* Commercial & industrial: grid battery storage.

## How to use the software

Set up the software by following the instructions in the “How to set up the software” section.

Once you’ve set it up:

1. Call the request API, to request the model to run, by following the instructions in the “Call the request API” section.
* Send your request to the model.
* The model solves the optimisation problem and generates the charging schedule for your device.

2. Call the result API, to retrieve the charging schedule, by following the instructions in the “Call the result API” section.
* Send your tracking id to the model.
* The software returns the charging schedule for the device.

## Architecture

![architecture diagram](https://github.com/smart-batteries/EV_Project_Lambdas/blob/main/info/architecture.png)

The software has two pipelines.

The first:

* Extracts price forecasts from the New Zealand Electricity Authority’s [WITS API](https://developer.electricityinfo.co.nz/WITS)
* Buffers the data with [AWS SQS](https://aws.amazon.com/sqs).
* Loads the data into a [PostgreSQL](https://postgresql.org) instance on [AWS RDS](https://aws.amazon.com/rds).

The second:

* Receives user requests and serves responses with [AWS API Gateway](https://aws.amazon.com/api-gateway).
* Orchestrates the response with [AWS Step Functions](https://aws.amazon.com/step-functions).

Overall:

* Process with [Docker](https://docker.com) images hosted on [AWS Lambda](https://aws.amazon.com/lambda).
* Create AWS resources with [Terraform](https://www.terraform.io/).





# How the software works

## ETL pipelines

There are two pipelines:

__Forecast pipeline__

1. Every 30 min: Extract short-term price forecasts from the WITS API.
2. Every 2 hours: Extract long-term price forecasts from the WITS API.
3. Forecasts are merged into the database:
  * new data is added;
  * outdated data is overwritten with the latest forecasts.
4. Historical forecasts (>1 month in the past) are purged from the database.

__User request pipeline__

1. The user calls the software’s API, to request the model to run.
* Extract input data from their API call, and transform it so it’s in a usable format for the model.
* Extract the price forecasts relevant to the request.
2. Pass the transformed input data & price forecasts to the model.
3. The model solves the optimisation problem and saves its output.

4. The user calls the software’s API, to retrieve their charging schedule.
5. Return the charging schedule to the user.

## Database schema

![ERD](https://github.com/smart-batteries/EV_Project_Lambdas/blob/main/info/ERD.png)

Tables:
  * __price_forecasts:__ electricity price forecasts.
  * __opt_requests:__ user request, as accepted by the user request API.
  * __opt_problems:__ user request, represented as an optimsation problem for the model.
  * __opt_prob_prices:__ the price forecast for each time period of the optimsation problem.
  * __opt_runs:__ data used by the model during optimisation
  * __opt_run_decisions:__ model output for each time period of the optimsation problem.





# How to set up the software

## Cloud account & remote repo

First, you’ll need to create an AWS account. The software should fit into their [free tier](https://aws.amazon.com/free), although we can't guarantee it won't cost cost you anything.

Then clone the repository into your home directory.
<pre>
git clone https://github.com/smart-batteries/EV_Project_Lambdas.git
cd EV_Project_Lambdas
</pre>

## WITS API

The price forecasts come from the New Zealand Electricity Authority’s WITS API.

**Steps:**

1. Create a [WITS developer account](https://developer.electricityinfo.co.nz/WITS).
2. Create an app.
  * The redirect URI doesn’t matter, you can use any URL.
  * Activate the Pricing_API_Application_Registration.
  * Save the WITS client id and secret for later.

_Background info:_

* _About the [New Zealand Electricity Authority](https://ea.govt.nz)._
* _[Why we use their WITS API, not their EMI API](https://forum.emi.ea.govt.nz/thread/three-wholesale-market-price-apis-to-be-decommissioned-on-21-october-2022)._
* _Documentation for the [Market Prices catalogue](https://developer.electricityinfo.co.nz/WITS/documentation/market-prices)._

## Amazon Web Services

The software consists of:
* Docker images to process data; these will be hosted on AWS Lambda.
* a database to store data; this will be hosted on an AWS RDS PostgreSQL instance.

**Steps:**

1. Create an [AWS account](https://aws.amazon.com).
  *  Follow the best practises, such as: creating an admin user separate to the root user; setting up MFA for each user.
2. [Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions) the AWS CLI.
  * You can verify installation by running: ```aws --version```
3. For a designated IAM user, grant it programmatic access, so it can access AWS API-based methods via the CLI. In the console, go to the IAM service > 'Users' > find (or create) the user > 'Security credentials' section > 'Access keys' section > 'Create access key' button. Save the AWS access key id and secret for later.
  * Store your private information securely, ideally in a password manager.
4. In your local terminal, run ```aws configure``` and enter your information.
  * Enter your user's AWS access key id and secret.
  * Enter the AWS region you'll use; for example, ```eu-north-1```.
    * Keep in mind, different regions having different pricing tiers and different schedules for rolling out new tools. ```eu-north-1``` and ```us-east-1``` are good defaults. Avoid Sao Paulo.
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
2. Edit the ```terraform/first/variables.tf``` doc with the AWS region you'll use; for example, ```"eu-north-1"```.
3. Change to the ```EV_Project_Lambdas/terraform/first``` directory and run:
<pre>
terraform init
terraform apply --auto-approve
</pre>

At this point, you should have empty repos on ECR and empty log groups on CloudWatch.

## Populate ECR repos

Now, you have empty repos on [ECR](https://aws.amazon.com/ecr/), which need to be populated by the Docker images.

If you've forked this repo to your own GitHub repo, you can automate this from there:
1. In the GitHut Actions secrets and variables section:
  * Add the variable ```AWS_REGION```. Use __the same__ region as you did in the ```terraform/first/variables.tf``` doc.
  * Add the secrets ```AWS_ACCESS_KEY_ID``` and ```AWS_ACCESS_KEY_SECRET```, to access AWS CLI.
2. Dispatch the ```.github/workflows/initial_deployment.yml``` workflow.

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

_Background info:_

* _Ideally, the RDS instance is in a private subnet; but in that case, for the pipeline to access it, it would need a NAT gateway, which incurs a monthly cost. Currently, the Terraform config builds an RDS instance in a public subnet. If you prefer to use a private subnet, the ```terraform/second/network/main.tf``` doc already has the relevant config for a NAT gateway; simply unhash it._

**Steps:**

1. Edit the ```terraform/second/variables.tf``` doc.
  * Use __the same__ AWS region as you did in the ```terraform/first/variables.tf``` doc.
  * Add the IP address of your home network (or wherever you want to connect to your database from).
  * Create a username and password to log in to your database. Save this for later.
  * Add the client id and secret from your WITS developer account.

2. Change to the ```EV_Project_Lambdas/terraform/second``` directory and run:
<pre>
terraform init
terraform apply --auto-approve
</pre>

At this point, you should have all the AWS resources you need.

## Set up the database

Your PostgreSQL instance is currently empty. You need to add the tables and stored procedures.

**Steps:**

1. To connect to your RDS instance, you can: Download pgAdmin 4 and add it as a server; or connect in the terminal by following [these instructions](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_CommonTasks.Connect.html). For either method, you'll need:

  *  Host: the RDS endpoint. You can find that either in the console's RDS section or via an AWS CLI command.
  *  Username: the username you set in the ```terraform/second/variables.tf``` doc.
  *  Password: the password you set in the ```terraform/second/variables.tf``` doc.
  *  Keep in mind: you need to be in the network you added to the ```connect_to_db``` security group in the ```terraform/second/variables.tf``` doc. (And disconnect from any VPNs.)

2. To create the tables & an enum data type, run each SQL command in the [database tables.sql](https://github.com/smart-batteries/EV_Project_Lambdas/blob/main/info/database%20tables.sql) doc.

3. To create the stored procedures & custom functions, run each SQL command in the [database procedures.sql](https://github.com/smart-batteries/EV_Project_Lambdas/blob/main/info/database%20procedures.sql) doc.

At this point, your instance of the software should be ready to use.

## Call the request API

1. Send a GET request to the request API, in this format:

```<invoke_url>/<route>?start=<start>&end=<end>&kwh=<kwh>&kw=<kw>&node=<node>```

  * invoke_url of the _request_ API: You can find this either in the console's API Gateway section or via an AWS CLI command.
  * route: ```run```. (Assuming you didn't change the ```route_key``` argument in the ```terraform/second/user_api/main.tf``` doc.)
  * start and end: The datetimes for when the device can start charging and when it has to be fully charged by. The format is ```YYYY-MM-DD%20HH:mm```, where the ```%20``` in the middle is a URL-encoded space.
  * kwh: How much electricity the device needs to charge, in kWh.
  * kw: How fast the device charges, in kW.
  * node: The location on the electricity grid. Use [this website](https://www.ea.govt.nz/your-power/your-meter/address) to input your address or ICP number, click "Show all connection information", then find the "POC". This is your node.
  
    For example, if sending a curl command from the terminal, it could look like this:

    <pre>
    curl -X GET "https://example_request_api_id.execute-api.aws_region.amazonaws.com/run?start=2024-02-01%2018:30&end=2024-02-02%2006:30&kwh=46&kw=7.7&node=WRD0331"
    </pre>

2. You'll receive a response, in the format below. Save this id for later; ideally, save the charging details of your input, as well.
    <pre>
    {
      "id" : "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    }
    </pre>
## Call the result API

1. Send a GET request to the result API, in this format:

```<invoke_url>/<route>?id=<id>```

  * invoke_url of the _result_ API: You can find this either in the console's API Gateway section or via an AWS CLI command.
  * route: ```result```. (Assuming you didn't change the ```route_key``` argument in the ```terraform/second/user_api/main.tf``` doc.)
  * id: The id you received when you called the request API.

    For example, if sending a curl command from the terminal, it could look like this:

    <pre>
    curl -X GET "https://example_result_api_id.execute-api.aws_region.amazonaws.com/result?id=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    </pre>
2. You'll receive a charging schedule for that device, in the format below.