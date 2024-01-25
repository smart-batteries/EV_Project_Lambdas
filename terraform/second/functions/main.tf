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
data "aws_ecr_repository" "solver" {
  name = "solver"
}
data "aws_ecr_repository" "return_result" {
  name = "return_result"
}
data "aws_ecr_repository" "return_result_inner" {
  name = "return_result_inner"
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
      CLIENT_ID     = var.client_id
      CLIENT_SECRET = var.client_secret
      QUEUE_URL     = var.queue_url
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
      CLIENT_ID     = var.client_id
      CLIENT_SECRET = var.client_secret
      QUEUE_URL     = var.queue_url
    }
  }
}

# Create Merge function

resource "aws_lambda_function" "merge" {
  function_name = "merge"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.merge.repository_url}:latest"
  role          = var.merge_role_arn
  timeout       = 60

  vpc_config {
    subnet_ids         = var.list_subnet_ids
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME   = var.db_name
      USER_NAME = var.username
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
  timeout       = 60

  vpc_config {
    subnet_ids         = var.list_subnet_ids
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME   = var.db_name
      USER_NAME = var.username
      PASSWORD  = var.password
    }
  }
}





# Create log_request function

resource "aws_lambda_function" "log_request" {
  function_name = "log_request"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.log_request.repository_url}:latest"
  role          = var.lambda_role_arn
  timeout       = 60

  vpc_config {
    subnet_ids = var.list_subnet_ids
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST          = var.rds_host
      DB_NAME           = var.db_name
      USER_NAME         = var.username
      PASSWORD          = var.password
    }
  }
}

# Create create_problem function

resource "aws_lambda_function" "create_problem" {
  function_name = "create_problem"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.create_problem.repository_url}:latest"
  role          = var.lambda_role_arn
  timeout       = 60

  vpc_config {
    subnet_ids         = var.list_subnet_ids
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME   = var.db_name
      USER_NAME = var.username
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
  timeout       = 60

  vpc_config {
    subnet_ids         = var.list_subnet_ids
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME   = var.db_name
      USER_NAME = var.username
      PASSWORD  = var.password
    }
  }
}

# Create solver function

resource "aws_lambda_function" "solver" {
  function_name = "solver"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.solver.repository_url}:latest"
  role          = var.lambda_role_arn
  timeout       = 60

  vpc_config {
    subnet_ids         = var.list_subnet_ids
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME   = var.db_name
      USER_NAME = var.username
      PASSWORD  = var.password
    }
  }
}






# Create return_result function

resource "aws_lambda_function" "return_result" {
  function_name = "return_result"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.return_result.repository_url}:latest"
  role          = var.return_result_arn
  timeout       = 120
}


# Create return_result_inner function

resource "aws_lambda_function" "return_result_inner" {
  function_name = "return_result_inner"
  package_type  = "Image"
  image_uri     = "${data.aws_ecr_repository.return_result_inner.repository_url}:latest"
  role          = var.return_result_arn
  timeout       = 60

  vpc_config {
    subnet_ids         = var.list_subnet_ids
    security_group_ids = [ var.lambda_to_rds_id ]
  }

  environment {
    variables = {
      RDS_HOST  = var.rds_host
      DB_NAME   = var.db_name
      USER_NAME = var.username
      PASSWORD  = var.password
    }
  }
}

