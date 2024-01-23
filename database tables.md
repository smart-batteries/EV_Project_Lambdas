CREATE TABLE price_forecasts (
    price_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    node CHAR(7),
    trading_datetime TIMESTAMP,
    trading_period SMALLINT,
    price NUMERIC(6,2),
    time_of_forecast TIMESTAMP,
    schedule_name VARCHAR(5)
);


CREATE TABLE opt_requests (
    request_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    kwh_to_charge REAL,
    kw_charge_rate REAL,
    node CHAR(7)
);


CREATE TABLE opt_problems (
    prob_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    request_id UUID REFERENCES opt_requests(request_id),
    periods_until_deadline SMALLINT,
    periods_of_charge_required SMALLINT
);


CREATE TABLE opt_prob_prices (
    prob_id UUID REFERENCES opt_problems(prob_id),
    price_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    price NUMERIC(6,2),
    trading_period SMALLINT,
    time_of_forecast TIMESTAMP
);


CREATE TYPE run_status_type AS ENUM ('created', 'pending', 'solved');


CREATE TABLE opt_runs (
    run_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    prob_id UUID REFERENCES opt_problems(prob_id),
    request_id UUID REFERENCES opt_requests(request_id),
    run_status run_status_type,
    objective_value NUMERIC,
    run_result INTEGER
);


CREATE TABLE opt_run_decisions (
    run_id UUID REFERENCES opt_runs(run_id),
    request_id UUID REFERENCES opt_requests(request_id),
    price_id UUID REFERENCES opt_prob_prices(price_id),
    decision_value BOOLEAN,
    period_no SMALLINT
);

