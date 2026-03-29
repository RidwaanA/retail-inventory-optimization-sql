/*
Project: Retail Inventory Optimization & Product Demand Analysis

Business Context:
GL-Kart is preparing for a forecasted 25% increase in product demand during the
holiday season. The supply and inventory team requires visibility into current
and future inventory risks to ensure timely order fulfillment.

Key Objectives:
- Evaluate current supply-to-demand ratios and classify inventory risk
- Identify customers with fully at-risk orders
- Simulate a 25% demand increase and quantify additional supply required

This analysis supports proactive procurement planning and operational
risk mitigation.
*/

/* =========================================================================
SECTION 01 — DATA FAMILIARIZATION & STRUCTURE VALIDATION
Objective: Understand schema relationships and validate operational tables
========================================================================= */

-- [1] Inspecting core operational tables

select * from address
limit 10;

select * from online_customer
limit 10;

select * from order_header
limit 10;

select * from order_items
limit 10;

select * from product
limit 10;

select * from product_class
limit 10;

select * from shipper
limit 10;


/* ===========================================================
SECTION 02 — SUPPLY & DEMAND DATA PREPARATION
Objective: Construct analysis-ready demand vs supply dataset
=========================================================== */

-- [2]
create temporary table DEMAND_SUPPLY
select
	OH.CUSTOMER_ID, OI.PRODUCT_ID, PRODUCT_DESC, OI.ORDER_ID, PC.PRODUCT_CLASS_DESC,
    sum(OI.PRODUCT_QUANTITY) as DEMAND,
    ceil(sum(OI.PRODUCT_QUANTITY) + (sum(OI.PRODUCT_QUANTITY) * 0.25)) as NEW_DEMAND,
    PRODUCT_QUANTITY_AVAIL as SUPPLY,
    round(PRODUCT_QUANTITY_AVAIL / sum(OI.PRODUCT_QUANTITY), 2) as CURRENT_RATIO,
    round(PRODUCT_QUANTITY_AVAIL / ceil(sum(OI.PRODUCT_QUANTITY) + (sum(OI.PRODUCT_QUANTITY) * 0.25)), 2) as NEW_RATIO
from orders.order_header as OH
	inner join orders.order_items as OI using(ORDER_ID)
    inner join orders.product using(PRODUCT_ID)
    inner join orders.product_class as PC using(PRODUCT_CLASS_CODE)
group by 1,2,3,4,5;

-- [3] Validate constructed dataset
select * from DEMAND_SUPPLY;

/* =================================================================
SECTION 03 — CURRENT INVENTORY RISK ASSESSMENT
Objective: Classify current stock position against existing demand
================================================================= */
-- [4] Stock Status Classification
/* Approach: 
	Status is:
    -- 1. SAFE, if stock/inventory is greater than or equal to 10% of demand
	-- 2. MATCHED, if stock/inventory is equal to demand
    -- 3. AT RISK, if stock/inventory is less than demand */
select
	CUSTOMER_ID,
    PRODUCT_ID,
    PRODUCT_DESC,
    ORDER_ID,
    DEMAND,
    PRODUCT_CLASS_DESC,
    SUPPLY,
		case
			when CURRENT_RATIO < 1 then 'AT RISK'
			when CURRENT_RATIO >= 1 and CURRENT_RATIO < 1.1 then 'MATCHED'
            when CURRENT_RATIO >= 1.1 then 'SAFE'
		end as STOCK_STATUS
from DEMAND_SUPPLY;

-- [5] Risk Distribution Percentage
select
	(sum(case when CURRENT_RATIO < 1 then 1 else 0 end)/count(*))*100 as 'AT_RISK_RATIO(%)',
    (sum(case when CURRENT_RATIO >= 1 and CURRENT_RATIO < 1.1 then 1 else 0 end)/count(*))*100 as 'MATCHED_RATIO(%)',
    (sum(case when CURRENT_RATIO >= 1.1 then 1 else 0 end)/count(*))*100 as 'SAFE_RATIO(%)'
from DEMAND_SUPPLY;

-- [6] Customers with Fully At-Risk Orders
select
	CUSTOMER_ID,
    count(*) as NUM_OF_ORDERS,
    sum(case when CURRENT_RATIO < 1 then 1 else 0 end) as ORDERS_AT_RISK,
    round((sum(case when CURRENT_RATIO < 1 then 1 else 0 end)/count(*))*100, 2) as '%AT_RISK'
from DEMAND_SUPPLY
group by 1
having ORDERS_AT_RISK = 1;

/* =====================================================================
SECTION 04 — HOLIDAY DEMAND SPIKE SIMULATION (+25%)
Objective: Evaluate inventory exposure under projected demand increase
===================================================================== */

-- [7] New Stock Status Under Increased Demand
select
	CUSTOMER_ID,
    PRODUCT_ID,
    PRODUCT_DESC,
    ORDER_ID,
    NEW_DEMAND,
    PRODUCT_CLASS_DESC,
    SUPPLY,
		case
			when NEW_RATIO < 1 then 'AT RISK'
			when NEW_RATIO >= 1 and NEW_RATIO < 1.1 then 'MATCHED'
            when NEW_RATIO >= 1.1 then 'SAFE'
		end as NEW_STOCK_STATUS
from DEMAND_SUPPLY;

-- [8] Updated Risk Distribution After Demand Surge
select
	(sum(case when NEW_RATIO < 1 then 1 else 0 end)/count(*))*100 as 'AT_RISK_RATIO(%)',
    (sum(case when NEW_RATIO >= 1 and NEW_RATIO < 1.1 then 1 else 0 end)/count(*))*100 as 'MATCHED_RATIO(%)',
    (sum(case when NEW_RATIO >= 1.1 then 1 else 0 end)/count(*))*100 as 'SAFE_RATIO(%)'
from DEMAND_SUPPLY;

/* =====================================================================
SECTION 05 — INVENTORY GAP QUANTIFICATION
Objective: Calculate additional stock required to reach safe threshold
===================================================================== */

-- [9]
select
	*,
    ceil(NEW_DEMAND*1.1) AS SAFE_INVENTORY,
    ceil(NEW_DEMAND*1.1) - SUPPLY as INVENTORY_NEEDED
from DEMAND_SUPPLY
where NEW_RATIO < 1;

/* =============================================================================
SECTION 06 — EXECUTIVE SUMMARY OUTPUT (BOARD-READY METRICS)
Objective: Provide operational KPIs for procurement planning
============================================================================= */

-- [10] Current Risk Exposure
select
    count(*) as total_orders,
    sum(case when CURRENT_RATIO < 1 then 1 else 0 end) as orders_at_risk,
    round((sum(case when CURRENT_RATIO < 1 then 1 else 0 end) / COUNT(*)) * 100, 2) as at_risk_percentage
from DEMAND_SUPPLY;

-- [11] Projected Risk Exposure (25% Demand Increase)
select
    count(*) as total_orders,
    sum(case when NEW_RATIO < 1 then 1 else 0 end) as projected_orders_at_risk,
    round((sum(case when NEW_RATIO < 1 then 1 else 0 end) / COUNT(*)) * 100, 2) as projected_at_risk_percentage
from DEMAND_SUPPLY;

-- [12] Total Additional Inventory Required
select
    sum(ceil(NEW_DEMAND * 1.1) - SUPPLY) as total_inventory_required
from DEMAND_SUPPLY
where NEW_RATIO < 1;

-- [13] Highest Risk Product Classes (Before Demand Increase)
select
    PRODUCT_CLASS_DESC,
    count(*) as at_risk_orders
from DEMAND_SUPPLY
where CURRENT_RATIO < 1
group by 1
order by 2 desc;

-- [14] Highest Risk Product Classes (After Demand Increase)
select
    PRODUCT_CLASS_DESC,
    count(*) as at_risk_orders
from DEMAND_SUPPLY
where NEW_RATIO < 1
group by 1
order by 2 desc;