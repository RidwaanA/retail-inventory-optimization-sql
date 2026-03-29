# Retail Inventory Optimization & Product Demand Analysis

# Project Overview
Developed an inventory analytics framework for **GL Kart Store** to assess stock risk, simulate demand surges, and quantify supply gaps for a retail business (**GL Kart Store**) operating across 35 cities in 5 countries.

The solution enables proactive inventory planning and risk mitigation ahead of a projected **25% increase in demand**.

# Business Problem
The supply team lacked visibility into:

- Inventory risk under current conditions
- Impact of increased demand on stock levels
- Quantity of additional inventory required

# 🗂 Data Overview
- 52 customers, 205 orders, 59 products
- Coverage across 35 cities / 5 countries
- Key data points: product availability, order quantities, product class, customer orders

# Tools & Technologies
- MySQL
- SQL (CTEs, aggregations, CASE logic, temporary tables)

# SQL Highlights
1. Demand vs Supply Modeling (Core Logic)

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

2. Inventory Risk Classification

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

3. Inventory Gap Quantification

select
	*,
    ceil(NEW_DEMAND*1.1) AS SAFE_INVENTORY,
    ceil(NEW_DEMAND*1.1) - SUPPLY as INVENTORY_NEEDED
from DEMAND_SUPPLY
where NEW_RATIO < 1;

# Key Insights
- Current inventory is largely healthy:
  - 96.1% of orders are safe, only 1.46% at risk
  - Just 3 orders currently at risk
- Demand surge significantly increases risk exposure:
  - At-risk orders rise from 3 → 9 orders
  - At-risk percentage increases to 4.39%
- Inventory pressure is concentrated, not widespread:
  - Only 3 customers currently have fully at-risk orders
  - Risk is driven by specific product categories, not all inventory
- Product-level risk concentration:
  - Stationery is the most vulnerable category
  - After demand increase, Kitchen Items and Furniture also become at risk
- Quantified supply gap:
  - Additional 47 units of inventory required to meet projected demand
 
# Recommendations
- Increase inventory proactively (high priority)
  - Procure at least 47 additional units to mitigate projected shortages
- Prioritize high-risk product categories
  - Focus on Stationery first, followed by Kitchen Items and Furniture
- Implement demand-driven inventory planning
  - Use demand forecasts to dynamically adjust stock levels
- Monitor at-risk customers and orders
  - Prevent fulfillment failures for high-risk transactions
- Introduce safety stock buffers
  - Maintain minimum inventory thresholds for critical products

# Outcome
Delivered a forward-looking inventory optimization model that identifies current risks, simulates demand shocks, and quantifies supply needs for data-driven procurement decisions.

# Next Steps
- Build inventory dashboards (Power BI/Tableau)
- Implement automated replenishment triggers
- Integrate real-time inventory tracking
- Develop demand forecasting models
