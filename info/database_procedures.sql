-- For merge function:


CREATE OR REPLACE PROCEDURE merge_create_stage()
LANGUAGE SQL
AS $$
    CREATE TEMP TABLE stage (
        node CHAR(7),
        trading_datetime TIMESTAMP,
        trading_period SMALLINT,
        price DECIMAL(6,2),
        time_of_forecast TIMESTAMP,
        schedule_name VARCHAR(5)
    );
$$;


CREATE OR REPLACE PROCEDURE merge_insert_stage(
    node CHAR(7),
    trading_datetime TIMESTAMP,
    trading_period SMALLINT,
    price DECIMAL(6,2),
    time_of_forecast TIMESTAMP,
    schedule_name VARCHAR(5)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO stage (
        node,
        trading_datetime,
        trading_period,
        price,
        time_of_forecast,
        schedule_name
    )
    VALUES (
        node,
        trading_datetime,
        trading_period,
        price,
        time_of_forecast,
        schedule_name
    );
END
$$;


CREATE OR REPLACE PROCEDURE merge_update_forecasts()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE price_forecasts AS f
    SET
        price = s.price,
        time_of_forecast = s.time_of_forecast,
        schedule_name = s.schedule_name
    FROM stage AS s
    WHERE
        f.node = s.node
        AND f.trading_datetime = s.trading_datetime
        AND s.time_of_forecast > f.time_of_forecast;
END
$$;


CREATE OR REPLACE PROCEDURE merge_insert_forecasts()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO price_forecasts (
        node,
        trading_datetime,
        trading_period,
        price,
        time_of_forecast,
        schedule_name
    )
    SELECT
        s.node,
        s.trading_datetime,
        s.trading_period,
        s.price,
        s.time_of_forecast,
        s.schedule_name
    FROM stage AS s
    WHERE NOT EXISTS (
        SELECT 1
        FROM price_forecasts AS f
        WHERE f.node = s.node
        AND f.trading_datetime = s.trading_datetime
    );
END
$$;




-- For purge function:


CREATE OR REPLACE FUNCTION purge_old_forecasts()
RETURNS VOID AS
$$
BEGIN
    DELETE FROM price_forecasts WHERE (trading_datetime + INTERVAL '1 month') < CURRENT_TIMESTAMP;
END
$$
LANGUAGE plpgsql;




-- For log_request function:


CREATE OR REPLACE FUNCTION insert_run_request(
    request_id_val UUID,
    start_time_val TIMESTAMP,
    end_time_val TIMESTAMP,
    kwh_to_charge_val REAL,
    kw_charge_rate_val REAL,
    node_val VARCHAR
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO opt_requests (request_id, start_time, end_time, kwh_to_charge, kw_charge_rate, node)
    VALUES (request_id_val, start_time_val, end_time_val, kwh_to_charge_val, kw_charge_rate_val, node_val);
END
$$ LANGUAGE plpgsql;





-- For create_problem function:


CREATE OR REPLACE FUNCTION extract_run_request(request_id_arg UUID)
RETURNS TABLE (
    start_time_val TIMESTAMP,
    end_time_val TIMESTAMP,
    kwh_to_charge_val NUMERIC,
    kw_charge_rate_val NUMERIC
)
AS $$
DECLARE
    start_time_val TIMESTAMP;
    end_time_val TIMESTAMP;
    kwh_to_charge_val NUMERIC;
    kw_charge_rate_val NUMERIC;
BEGIN
    SELECT start_time, end_time, kwh_to_charge, kw_charge_rate 
    INTO start_time_val, end_time_val, kwh_to_charge_val, kw_charge_rate_val
    FROM opt_requests 
    WHERE request_id = request_id_arg;
    RETURN QUERY SELECT start_time_val, end_time_val, kwh_to_charge_val, kw_charge_rate_val;
END
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION insert_opt_problem(
    request_id_val UUID,
    periods_until_deadline_val INT,
    periods_of_charge_required_val INT
)
RETURNS UUID AS $$
DECLARE
    returning_id UUID;
BEGIN
    INSERT INTO opt_problems (prob_id, request_id, periods_until_deadline, periods_of_charge_required)
    VALUES (DEFAULT, request_id_val, periods_until_deadline_val::SMALLINT, periods_of_charge_required_val::SMALLINT)
    RETURNING prob_id INTO returning_id;
    RETURN returning_id;
END
$$ LANGUAGE plpgsql;



-- For get_prices function:


CREATE OR REPLACE FUNCTION extract_time_window(prob_id_arg UUID)
RETURNS TABLE (
    start_time_val TIMESTAMP,
    end_time_val TIMESTAMP,
    node_val VARCHAR
)
AS $$
DECLARE
    start_time_val TIMESTAMP;
    end_time_val TIMESTAMP;
    node_val VARCHAR;
BEGIN
    SELECT start_time, end_time, node
    INTO start_time_val, end_time_val, node_val
    FROM opt_problems
    JOIN opt_requests ON opt_problems.request_id = opt_requests.request_id
    WHERE opt_problems.prob_id = prob_id_arg;
    RETURN QUERY SELECT start_time_val, end_time_val, node_val;
END
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION extract_prob_prices(
    start_time_arg TIMESTAMP,
    end_time_arg TIMESTAMP,
    node_arg VARCHAR
)
RETURNS TABLE (
    node_val VARCHAR,
    trading_period_val SMALLINT,
    price_val NUMERIC,
    time_of_forecast_val TIMESTAMP
)
AS $$
DECLARE
    record_row RECORD;
BEGIN
    FOR record_row IN
        SELECT node, trading_period, price, time_of_forecast
        FROM price_forecasts
        WHERE node = node_arg
        AND trading_datetime >= start_time_arg
        AND trading_datetime <= end_time_arg
    LOOP
        node_val := record_row.node;
        trading_period_val := record_row.trading_period;
        price_val := record_row.price;
        time_of_forecast_val := record_row.time_of_forecast;
        RETURN NEXT;
    END LOOP;
END
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION insert_prob_prices(
    prob_id_val UUID,
    price_val NUMERIC,
    trading_period_val INT,
    time_of_forecast_val TIMESTAMP
)
RETURNS UUID AS $$
DECLARE
    returning_id UUID;
BEGIN
    INSERT INTO opt_prob_prices (prob_id, price_id, price, trading_period, time_of_forecast)
    VALUES (prob_id_val, DEFAULT, price_val, trading_period_val::SMALLINT, time_of_forecast_val)
    RETURNING price_id INTO returning_id;
    RETURN returning_id;
END
$$ LANGUAGE plpgsql;




-- For solver function:



















-- For return_results_inner function:


CREATE OR REPLACE FUNCTION extract_model_decisions(request_id_arg UUID)
RETURNS TABLE (
    trading_datetime_val TIMESTAMP,
    decision_value_val BOOL,
    price_val NUMERIC
)
AS $$
DECLARE
    record_row RECORD;
BEGIN
    FOR record_row IN
        SELECT trading_datetime, decision_value, opt_run_decisions.price
        FROM opt_run_decisions
        JOIN price_forecasts ON opt_run_decisions.price_id = price_forecasts.price_id
        WHERE opt_run_decisions.request_id = request_id_arg
    LOOP
        trading_datetime_val := record_row.trading_datetime;
        decision_value_val := record_row.decision_value;
        price_val := record_row.price;
        RETURN NEXT;
    END LOOP;
END
$$ LANGUAGE plpgsql;