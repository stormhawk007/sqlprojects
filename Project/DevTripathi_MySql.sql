/*1.) Write a query to Display the product details (product_class_code, product_id, product_desc, product_price,) 
as per the following criteria and sort them in descending order of category: 
			a. If the category is 2050, increase the price by 2000 
			b. If the category is 2051, increase the price by 500 
			c. If the category is 2052, increase the price by 600.
Sol: */

SELECT PRODUCT_CLASS_CODE, PRODUCT_ID, PRODUCT_DESC,
CASE PRODUCT_CLASS_CODE WHEN 2050 THEN PRODUCT_PRICE+2000
						WHEN 2051 THEN PRODUCT_PRICE+500
						WHEN 2052 THEN PRODUCT_PRICE+600
						ELSE PRODUCT_PRICE END AS PRODUCT_PRICE
FROM PRODUCT
ORDER BY PRODUCT_CLASS_CODE DESC;
/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 2.) Write a query to display (product_class_desc, product_id, product_desc, product_quantity_avail ) and 
 Show inventory status of products as below as per their available quantity: 
 		a. For Electronics and Computer categories, if available quantity is <= 10, show 'Low stock', 11 <= qty <= 30, show 'In stock', >= 31, show 'Enough stock' 
 		b. For Stationery and Clothes categories, if qty <= 20, show 'Low stock', 21 <= qty <= 80, show 'In stock', >= 81, show 'Enough stock' 
		c. Rest of the categories, if qty <= 15 – 'Low Stock', 16 <= qty <= 50 – 'In Stock', >= 51 – 'Enough stock' For all categories, if available quantity is 0, show 'Out of stock'. 
 Sol: */

SELECT PRODUCT_CLASS_DESC,PRODUCT_ID,PRODUCT_DESC,PRODUCT_QUANTITY_AVAIL,
CASE 
	WHEN PRODUCT_QUANTITY_AVAIL =0
	THEN "Out of stock"
	WHEN PRODUCT_CLASS_DESC IN ("Electronics","Computer")
	THEN 
		CASE 
			WHEN PRODUCT_QUANTITY_AVAIL <11 
			THEN "Low stock"
			WHEN PRODUCT_QUANTITY_AVAIL  BETWEEN 11 AND 30 
			THEN "In stock"
			WHEN PRODUCT_QUANTITY_AVAIL >=31
			THEN "Enough stock"
		END
	WHEN PRODUCT_CLASS_DESC IN ("Stationery","Clothes")
	THEN
		CASE 
			WHEN PRODUCT_QUANTITY_AVAIL <21 
			THEN "Low stock"
			WHEN PRODUCT_QUANTITY_AVAIL  BETWEEN 21 AND 80 
			THEN "In stock"
			WHEN PRODUCT_QUANTITY_AVAIL >=81
			THEN "Enough stock"
		END
	ELSE
		CASE 
			WHEN PRODUCT_QUANTITY_AVAIL <16
			THEN "Low stock"
			WHEN PRODUCT_QUANTITY_AVAIL  BETWEEN 16 AND 50
			THEN "In stock"
			WHEN PRODUCT_QUANTITY_AVAIL >=51
			THEN "Enough stock"
		END
	END AS INVENTORY_STATUS
FROM PRODUCT JOIN PRODUCT_CLASS
USING(PRODUCT_CLASS_CODE)
ORDER BY PRODUCT_CLASS_DESC;

/*---------------------------------------------------------------------------------------------------------------------------------------
3.) Write a query to show the number of cities in all countries other than USA & MALAYSIA,
	with more than 1 city, in the descending order of CITIES. 
Sol:*/
SELECT COUNTRY,COUNT(CITY) AS CITIES 
FROM ADDRESS
WHERE COUNTRY NOT IN ("USA","Malaysia")
GROUP BY COUNTRY
HAVING COUNT(CITY)>1;

/*---------------------------------------------------------------------------------------------------------------------------------------
4. write a query to display the customer_id,customer full name ,city,pincode,and order details 
	(order id, product class desc, product desc, subtotal(product_quantity * product_price)) 
	for orders shipped to cities whose pin codes do not have any 0s in them. 
	sort the output on customer name and subtotal. (52 rows)
	[note: table to be used - online_customer, address, order_header, order_items, product, product_class]
Sol:*/

SELECT CUSTOMER_ID,CUSTOMER_FULL_NAME,CITY,PINCODE,ORDER_ID,PRODUCT_CLASS_DESC,PRODUCT_DESC,(PRODUCT_PRICE*PRODUCT_QUANTITY_AVAIL) AS SUBTOTAL
FROM 
	(SELECT CUSTOMER_ID,CUSTOMER_FULL_NAME,CITY,PINCODE,ORDER_ID,PRODUCT_PRICE,PRODUCT_QUANTITY_AVAIL,PRODUCT_CLASS_CODE,PRODUCT_DESC
	FROM
		(SELECT CUSTOMER_ID,CUSTOMER_FULL_NAME,CITY,PINCODE,CUSTOMER_ORDER.ORDER_ID,PRODUCT_ID
		FROM
			(SELECT CUSTOMER_INFO.CUSTOMER_ID,CUSTOMER_FULL_NAME, CITY, PINCODE,ORDER_HEADER1.ORDER_ID
			FROM 
				(SELECT *,CONCAT(CUSTOMER_FNAME,' ',CUSTOMER_LNAME) AS CUSTOMER_FULL_NAME
				 FROM ONLINE_CUSTOMER 
                 JOIN ADDRESS 
                 USING(ADDRESS_ID)) 
				 
			AS CUSTOMER_INFO			 
			JOIN (SELECT * FROM ORDER_HEADER WHERE ORDER_HEADER.ORDER_STATUS = "Shipped") AS ORDER_HEADER1
			USING(CUSTOMER_ID))
			
		AS CUSTOMER_ORDER
		JOIN ORDER_ITEMS
		USING(ORDER_ID))
		
	AS CUSTOMER_PRODUCT
	JOIN PRODUCT
	USING(PRODUCT_ID))
AS FINAL
JOIN PRODUCT_CLASS
USING(PRODUCT_CLASS_CODE)
WHERE PINCODE NOT LIKE "%0%"
ORDER BY CUSTOMER_FULL_NAME,SUBTOTAL;


/*---------------------------------------------------------------------------------------------------------------------------------------
5. Write a Query to display product id,product description,totalquantity(sum(product quantity) 
	for a given item whose product id is 201 and which item has been bought along with it maximum no. of times.
	Display only one record which has the maximum value for total quantity in this scenario.
	(USE SUB-QUERY)(1 ROW)[NOTE : ORDER_ITEMS TABLE,PRODUCT TABLE]
Sol:*/

SELECT PRODUCT.PRODUCT_ID,PRODUCT_DESC,SUM(PRODUCT_QUANTITY) AS TOTAL_QUANTITY 
FROM
	(SELECT PROD_201.ORDER_ID,ORDER_ITEMS.PRODUCT_ID,ORDER_ITEMS.PRODUCT_QUANTITY 
	 FROM ORDER_ITEMS 
	 JOIN (SELECT * FROM ORDER_ITEMS
		   WHERE PRODUCT_ID=201)
		  
	AS PROD_201
	USING(ORDER_ID)
	WHERE ORDER_ITEMS.PRODUCT_ID !=201)
	
AS PRODUCTS_WITH201
JOIN PRODUCT
USING(PRODUCT_ID)
GROUP BY PRODUCT_ID
ORDER BY TOTAL_QUANTITY DESC
LIMIT 1;

/*-----------------------------------------------------------------------------------------------------------------------------------------
6. Write a query to display the customer_id,customer name, email and order details
 (order id, product desc,product qty, subtotal(product_quantity * product_price)) 
 for all customers even if they have not ordered any item.(225 ROWS) 
 [NOTE: TABLE TO BE USED - online_customer, order_header, order_items, product]
Sol:*/
SELECT CUSTOMER_ID,CUSTOMER_FULL_NAME,CUSTOMER_EMAIL,ALL_CUSTOMER.ORDER_ID,PRODUCT_DESC,PRODUCT_QUANTITY,SUBTOTAL 
FROM 
	(SELECT ONLINE_CUSTOMER.CUSTOMER_ID, CONCAT(CUSTOMER_FNAME,' ',CUSTOMER_LNAME) AS CUSTOMER_FULL_NAME, CUSTOMER_EMAIL,ORDER_ID
	FROM ONLINE_CUSTOMER LEFT JOIN ORDER_HEADER
	USING(CUSTOMER_ID))AS ALL_CUSTOMER

LEFT JOIN
	(SELECT ORDER_ID,PRODUCT_DESC,PRODUCT_QUANTITY,(PRODUCT_QUANTITY*PRODUCT_PRICE) AS SUBTOTAL 
	FROM ORDER_ITEMS JOIN PRODUCT 
	USING(PRODUCT_ID)) AS ORD_PROD
	
USING(ORDER_ID);

/* -----------------------------------------------------------------------------------------------------------------------------------------
7. Write a query to display carton id, (len*width*height) as carton_vol and 
 identify the optimum carton (carton with the least volume whose volume is greater than the total volume of all items
 (len * width * height * product_quantity)) for a given order whose order id is 10006, 
 Assume all items of an order are packed into one single carton (box). (1 ROW) [NOTE: CARTON TABLE]
Sol:*/
SELECT CARTON_ID, (LEN * WIDTH * HEIGHT) AS CARTON_VOL
FROM CARTON
HAVING CARTON_VOL >(SELECT SUM(TOTAL_VOLUME)
					FROM (SELECT O_10006.PRODUCT_ID, PRODUCT_DESC, (PRODUCT_QUANTITY * LEN * WIDTH * HEIGHT) AS TOTAL_VOLUME
						  FROM (SELECT  *
								FROM order_items
								WHERE ORDER_ID = 10006) AS O_10006
						JOIN PRODUCT 
						USING(PRODUCT_ID)) AS PROD_10006)
ORDER BY CARTON_VOL ASC
LIMIT 1;

/*---------------------------------------------------------------------------------------------------------------------------------
8. Write a query to display details (customer id,customer fullname,order id,product quantity) of customers who bought more than ten 
   (i.e. total order qty) products with credit card or Net banking as the mode of payment per shipped order. 
   (6 ROWS) [NOTE: TABLES TO BE USED - online_customer, order_header, order_items,]
Sol:*/
SELECT CUSTOMER_ID, CONCAT(CUSTOMER_FNAME,' ',CUSTOMER_LNAME) AS CUSTOMER_FULL_NAME, ORDER_ID, SUM(PRODUCT_QUANTITY) AS TOTAL_PRODUCT_QUANTITY
FROM ONLINE_CUSTOMER
LEFT JOIN ORDER_HEADER USING(CUSTOMER_ID)
LEFT JOIN ORDER_ITEMS USING(ORDER_ID) 
WHERE ORDER_STATUS ='SHIPPED' AND PAYMENT_MODE IN ('CREDIT CARD','NET BANKING')
GROUP BY ORDER_ID HAVING SUM(PRODUCT_QUANTITY)>10;	

/*------------------------------------------------------------------------------------------------------------------------------------

9. Write a query to display the order_id, customer id and cutomer full name of customers
   starting with the alphabet "A" along with (product_quantity)
   as total quantity of products shipped for order ids > 10030. 
   (5 ROWS) [NOTE: TABLES TO BE USED - online_customer, order_header, order_items]
 Sol: */

SELECT CUST_ORD.ORDER_ID,CUSTOMER_ID,CUSTOMER_FULL_NAME,SUM(PRODUCT_QUANTITY) AS TOTAL_QUANTITY
FROM (SELECT ONLINE_CUSTOMER.CUSTOMER_ID, CONCAT(CUSTOMER_FNAME,' ',CUSTOMER_LNAME) AS CUSTOMER_FULL_NAME,ORDER_ID
	 FROM ONLINE_CUSTOMER
	 JOIN (SELECT * FROM ORDER_HEADER WHERE ORDER_STATUS='Shipped') AS SHIPPED_ORDERS
	 USING (CUSTOMER_ID)
     WHERE CUSTOMER_FNAME LIKE 'A%') AS CUST_ORD
JOIN ORDER_ITEMS
USING(ORDER_ID)
WHERE CUST_ORD.ORDER_ID>10030
GROUP BY ORDER_ITEMS.ORDER_ID;

/*-------------------------------------------------------------------------------------------------------------------------------------
10. Write a query to display product class description ,total quantity (sum(product_quantity),
Total value (product_quantity * product price) and show which class of products have been shipped highest(Quantity)
to countries outside India other than USA? Also show the total value of those items.
(1 ROWS)[NOTE:PRODUCT TABLE,ADDRESS TABLE,ONLINE_CUSTOMER TABLE,ORDER_HEADER TABLE,ORDER_ITEMS TABLE,PRODUCT_CLASS TABLE]
Sol:*/

SELECT PRODUCT_CLASS_DESC, SUM(PRODUCT_QUANTITY) AS TOTAL_QUANTITY, SUM(PRODUCT_QUANTITY*PRODUCT_PRICE) AS TOTAL_VALUE 
FROM PRODUCT_CLASS C
JOIN PRODUCT AS P USING(PRODUCT_CLASS_CODE)
JOIN ORDER_ITEMS AS O_I USING(PRODUCT_ID)
JOIN (SELECT * FROM ORDER_HEADER WHERE ORDER_STATUS = 'Shipped') AS O_H USING(ORDER_ID)
JOIN ONLINE_CUSTOMER AS CUST USING(CUSTOMER_ID)
JOIN (SELECT * FROM ADDRESS WHERE COUNTRY NOT IN ('INDIA','USA')) AS AD_S USING(ADDRESS_ID)
GROUP BY C.PRODUCT_CLASS_DESC
ORDER BY TOTAL_QUANTITY DESC
LIMIT 1;

-- //---------------------------------------------------------------------------------------------------------------//-----------------