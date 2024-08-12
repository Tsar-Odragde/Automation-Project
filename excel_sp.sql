-- Create a new stored procedure
CREATE OR REPLACE FUNCTION etl_process()
RETURNS void AS $$
BEGIN
    -- Transform and insert data from temp table to product table
    INSERT INTO product (product_name, product_cat, product_subcat, product_container, product_unit_price, product_ship_cost, product_base_margin)
    SELECT DISTINCT
		INITCAP(TRIM(t.product_name)), 
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.product_cat, E'[^a-zA-Z0-9 ]', '', 'g'))),
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.product_subcat, E'[^a-zA-Z0-9 ]', '', 'g'))), 
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.product_cont, E'[^a-zA-Z0-9 ]', '', 'g'))), 
        t.unit_price,
        t.ship_cost,
        t.product_base_margin
    FROM temp AS t
	LEFT JOIN product AS p ON INITCAP(TRIM(t.product_name)) = p.product_name
    WHERE p.product_name IS NULL;
	
	INSERT INTO customer (customer_id, customer_name)
    SELECT DISTINCT 
        t.customer_id,
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.customer_name, E'[^a-zA-Z0-9 ]', '', 'g')))
    FROM temp AS t
	LEFT JOIN customer AS c USING (customer_id)
    WHERE c.customer_id IS NULL;
	
    INSERT INTO location (country, region, state, city, postal_code)
    SELECT DISTINCT
		INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.country, E'[^a-zA-Z0-9 ]', '', 'g'))),
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.region, E'[^a-zA-Z0-9 ]', '', 'g'))),
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.state, E'[^a-zA-Z0-9 ]', '', 'g'))),
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.city, E'[^a-zA-Z0-9 ]', '', 'g'))),
        t.postal_code
	FROM temp AS t
	LEFT JOIN location AS l USING (postal_code)
    WHERE l.postal_code IS NULL
    ON CONFLICT DO NOTHING;
    
	INSERT INTO "order" (order_id, customer_id, product_id, postal_code, order_prio, ship_mode, discount, order_date, ship_date, customer_segment, sales, profit, qty_ordered, row_id)
    SELECT DISTINCT
        t.order_id, 
        t.customer_id, 
        p.product_id, 
        t.postal_code,
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.order_prio, E'[^a-zA-Z0-9 ]', '', 'g'))),
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.ship_mode, E'[^a-zA-Z0-9 ]', '', 'g'))), 
        t.discount,
        CAST(INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.order_date, E'[^a-zA-Z0-9 ]', '', 'g'))) AS DATE),
        CAST(INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.ship_date, E'[^a-zA-Z0-9 ]', '', 'g'))) AS DATE),
        INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.customer_segment, E'[^a-zA-Z0-9 ]', '', 'g'))),
        t.sales,
        t.profit,
        CAST(INITCAP(TRIM(BOTH ' ' FROM REGEXP_REPLACE(t.qty_ordered, E'[^a-zA-Z0-9 ]', '', 'g'))) AS INTEGER),
        t.row_id
    FROM temp AS t
	LEFT JOIN "order" AS o ON t.order_id = o.order_id AND t.row_id = o.row_id
    LEFT JOIN product AS p ON INITCAP(TRIM(t.product_name)) = p.product_name
    WHERE o.order_id IS NULL
    ON CONFLICT DO NOTHING;
	
END;
$$ LANGUAGE plpgsql;

-- Create an AFTER INSERT trigger to execute the etl_process stored procedure
CREATE OR REPLACE FUNCTION etl_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    -- Call the etl_process stored procedure
    PERFORM etl_process();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the 'temp' table
CREATE TRIGGER etl_trigger
AFTER INSERT ON temp
FOR EACH ROW
EXECUTE FUNCTION etl_trigger_function();