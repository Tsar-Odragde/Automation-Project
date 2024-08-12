CREATE OR REPLACE VIEW excel_query AS
    SELECT 
        o.row_id AS "Row ID",
        o.order_prio AS "Order Priority",
        o.discount AS Discount,
        p.product_unit_price AS "Unit Price",
        p.product_ship_cost AS "Shipping Cost",
        c.customer_id AS "Customer ID",
        c.customer_name AS "Customer Name",
        o.ship_mode AS "Ship Mode",
        o.customer_segment AS "Customer Segment",
        p.product_cat AS "Product Category",
        p.product_subcat AS "Product Sub-Category",
        p.product_container AS "Product Container",
        p.product_name AS "Product Name",
        p.product_base_margin AS "Product Base Margin",
        l.country AS "Country",
        l.region AS "Region",
        l.state AS "State or Province",
        l.city AS "City",
        l.postal_code AS "Postal Code",
        o.order_date AS "Order Date",
        o.ship_date AS "Ship Date",
        o.profit AS "Profit",
        o.qty_ordered AS "Quantity ordered new",
        o.sales AS "Sales",
        o.order_id AS "Order ID"
    FROM "order" AS o
    LEFT JOIN product AS p USING (product_id)
    LEFT JOIN customer AS c USING (customer_id)
    LEFT JOIN location AS l USING (postal_code);