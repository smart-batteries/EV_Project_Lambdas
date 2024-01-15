

# Set ECR repos for the functions

data "aws_ecr_repository" "prss" {
  name = "prss"
}
data "aws_ecr_repository" "prsl" {
  name = "prsl"
}
data "aws_ecr_repository" "merge" {
  name = "merge"
}
data "aws_ecr_repository" "purge" {
  name = "purge"
}
data "aws_ecr_repository" "log_request" {
  name = "log_request"
}
data "aws_ecr_repository" "create_problem" {
  name = "create_problem"
}
data "aws_ecr_repository" "get_prices" {
  name = "get_prices"
}







# Create PRSS function

resource "aws_lambda_function" "prss" {
  function_name = "prss"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.prss.repository_url}:latest"
  role          = var.wits_role_arn
  timeout       = 30

  environment {
    variables = {
      CLIENT_ID = var.client_id
      CLIENT_SECRET  = var.client_secret
      QUEUE_URL  = var.queue_url
    }
  }
}

# Create PRSL function

resource "aws_lambda_function" "prsl" {
  function_name = "prsl"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.prsl.repository_url}:latest"
  role          = var.wits_role_arn
  timeout       = 30

  environment {
    variables = {
      CLIENT_ID = var.client_id
      CLIENT_SECRET  = var.client_secret
      QUEUE_URL  = var.queue_url
    }
  }
}

# Allow EventBridge schedules to trigger invocation of PRSS & PRSL functions

resource "aws_cloudwatch_event_target" "trigger_prss_function" {
    rule = var.prss_schedule_name
    target_id = "prss"
    arn = aws_lambda_function.prss.arn
}

resource "aws_cloudwatch_event_target" "trigger_prsl_function" {
    rule = var.prsl_schedule_name
    target_id = "prsl"
    arn = aws_lambda_function.prsl.arn
}








# Create Merge function

resource "aws_lambda_function" "merge" {
  function_name = "merge"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.merge.repository_url}:latest"
  role          = var.merge_role_arn
  timeout       = 30

  vpc_config {
    subnet_ids = [ var.subnet_1_id, var.subnet_2_id ]
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME  = var.db_name
      USER_NAME  = var.username
      PASSWORD  = var.password
    }
  }
}

# Create Purge function

resource "aws_lambda_function" "purge" {
  function_name = "purge"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.purge.repository_url}:latest"
  role          = var.lambda_role_arn
  timeout       = 30

  vpc_config {
    subnet_ids = [ var.subnet_1_id, var.subnet_2_id ]
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME  = var.db_name
      USER_NAME  = var.username
      PASSWORD  = var.password
    }
  }
}

# Allow EventBridge schedules to trigger invocation of Purge function

resource "aws_cloudwatch_event_target" "trigger_purge_function" {
    rule = var.purge_schedule_name
    target_id = "purge"
    arn = aws_lambda_function.purge.arn
}








# Create log_request function

resource "aws_lambda_function" "log_request" {
  function_name = "log_request"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.log_request.repository_url}:latest"
  role          = var.lambda_role_arn
  timeout       = 30

  vpc_config {
    subnet_ids = [ var.subnet_3_id, var.subnet_4_id ]
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME  = var.db_name
      USER_NAME  = var.username
      PASSWORD  = var.password
    }
  }
}

# Create create_problem function

resource "aws_lambda_function" "create_problem" {
  function_name = "create_problem"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.create_problem.repository_url}:latest"
  role          = var.lambda_role_arn
  timeout       = 30

  vpc_config {
    subnet_ids = [ var.subnet_3_id, var.subnet_4_id ]
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME  = var.db_name
      USER_NAME  = var.username
      PASSWORD  = var.password
    }
  }
}

# Create get_prices function

resource "aws_lambda_function" "get_prices" {
  function_name = "get_prices"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.get_prices.repository_url}:latest"
  role          = var.lambda_role_arn
  timeout       = 30

  vpc_config {
    subnet_ids = [ var.subnet_3_id, var.subnet_4_id ]
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME  = var.db_name
      USER_NAME  = var.username
      PASSWORD  = var.password
    }
  }
}



