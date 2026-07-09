--Vista inicial
SELECT TOP 25 *
FROM Global_Sales

SELECT
Count(Order_ID) N_filas
FROM Global_Sales

-- Ventas regionales por categoría
	-- Ordenado por región
SELECT
	Region,
	Product_Category,
	FORMAT(SUM(Total_Sales), '$ #,###') Sales_Segment,
	FORMAT(SUM(Profit), '$ #,###') Profit_Segment
FROM Global_Sales
GROUP BY Region, Product_Category
ORDER BY Region, Product_Category

	-- Ordenado por Utilidad
SELECT
	Region,
	Product_Category,
	FORMAT(SUM(Total_Sales), '$ #,###') Sales_Segment,
	FORMAT(SUM(Profit), '$ #,###') Profit_Segment
FROM Global_Sales
GROUP BY Region, Product_Category
ORDER BY SUM(Profit) DESC

-- Paises rankeados por margen por región
WITH Margen_Pais AS (
    SELECT
        Region,
        Country,
        SUM(Total_Sales) Total_Sales,
        SUM(Profit) Total_Profit,
        ROUND(SUM(Profit) / SUM(Total_Sales), 2) Margen_Perc
    FROM Global_Sales
    GROUP BY Region, Country)

SELECT
	RANK() OVER (PARTITION BY Region ORDER BY Margen_Perc DESC) Ranking,
    Region,
    Country,
    FORMAT(Total_Sales, '$ #,###') Total_Sales,
    FORMAT(Total_Profit, '$ #,###') Total_Profit,
    FORMAT(Margen_Perc, 'P1') Margen_Pct
FROM Margen_Pais
ORDER BY Region, Margen_Pct DESC

-- Productos más vendidos
SELECT 
	Product_Name,
	Product_Category,
	FORMAT(SUM(Total_Sales), '$ #,###') Sales_Segment,
	FORMAT(SUM(Profit), '$ #,###') Profit_Segment
FROM Global_Sales
GROUP BY Product_Name, Product_Category
ORDER BY SUM(Profit) DESC

--Categorías más vendidas
SELECT 
	Product_Category,
	FORMAT(SUM(Total_Sales), '$ #,###') Sales_Segment,
	FORMAT(SUM(Profit), '$ #,###') Profit_Segment
FROM Global_Sales
GROUP BY Product_Category
ORDER BY SUM(Profit) DESC

--Ventas acumuladas y su % respecto al año
SELECT
    YEAR(Order_Date) Año,
    MONTH(Order_Date) Mes,
    FORMAT(SUM(Total_Sales), '$ #,###') Ventas_Mes,
    FORMAT(SUM(SUM(Total_Sales)) OVER (
            PARTITION BY YEAR(Order_Date) ORDER BY MONTH(Order_Date)
        ), '$ #,###') Ventas_Acumuladas,
    FORMAT(SUM(Total_Sales) / SUM(SUM(Total_Sales)) OVER (
            PARTITION BY YEAR(Order_Date)), 'P') Participacion_Anual
FROM Global_Sales
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY YEAR(Order_Date), MONTH(Order_Date)

--Ventas por Medio de pago
SELECT
	Payment_Method,
	FORMAT(SUM(Total_Sales), '$ #,###') Total_Sales,
	FORMAT(
		SUM(Total_Sales) / SUM(SUM(Total_Sales)) OVER(), 
		'P') AS '% Sales'
FROM Global_Sales
GROUP BY Payment_Method
ORDER BY SUM(Total_Sales) DESC

--Ventas por país
SELECT
	Country,
	FORMAT(SUM(Total_Sales), '$ #,###') Sales,
	FORMAT(SUM(Profit), '$ #,###') Profit
FROM Global_Sales
GROUP BY Country
ORDER BY SUM(Profit) DESC