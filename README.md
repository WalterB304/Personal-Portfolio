# Dashboard Comercial — Power BI + SQL Server

Dashboard de análisis comercial construido en SQL Server y exportado a Power BI, orientado a la toma de decisiones comerciales

[Ver Dashboard en Power BI](https://app.powerbi.com/view?r=eyJrIjoiZGRkNTcxODUtNTAyOC00N2I0LWI4YzUtYjY3MzM0Njc1ZWUyIiwidCI6ImZjZDlhYmQ4LWRmY2QtNGExYS1iNzE5LThhMTNhY2ZkNWVkOSIsImMiOjR9&pageName=351cb590cbbdbb5c4256)

---

## Contexto

Las empresas necesitan monitorear constantemente su desempeño comercial, qué mercados son más rentables, qué productos lideran las ventas, cómo evolucionan los resultados mes a mes y dónde se concentran las oportunidades de mejora.

Este proyecto busca simular un flujo de trabajo de un analista comercial: Almacenamiento y exploración inicial de los datos obtenidos a través de SQL Server, para su posterior exportación a Power BI y la construcción de un dashboard con métricas y gráficos de interés para el negocio

---

## Estructura del proyecto

```
Personal-Portfolio/Dashboard_Comercial
│
├──Images
│	└──Dashboard_1.png
│	└──Dashboard_2.png
│
├── Global_Sales.csv               # Dataset 
│
├── Global Sales.sql               # Consultas de exploración y análisis inicial
│
├── Global_Sales_Dashboard.pbix    # Dashboard de Power BI
│
└── README.md
```

---

## Exploración en SQL Server

La exploración inicial se realizó directamente en **SQL Server Management Studio (SSMS)**, validando los datos, respondiendo preguntas de negocio con queries y luego exponiendo los resultados en el dashboard de Power BI.

### Consultas principales
* NOTA: Por temas de espacio, se limitarán los resultados de las consultas
#### Vista inicial del dataset
```sql
SELECT TOP 5 *
FROM Global_Sales
```
|Order\_ID|Order\_Date|Customer\_Name|Customer\_Segment|Country|Region|Product\_Category|Product\_Name|Quantity|Unit\_Price|Discount\_Percent|Total\_Sales|Shipping\_Cost|Profit|Payment\_Method|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|ORD\-10001|2023\-07\-29|Joseph Johnson|Corporate|United States|North America|Office Supplies|Tape Dispenser Heavy Duty|2|948|0|1896|687|356|PayPal|
|ORD\-10002|2025\-05\-09|Patricia Leroy|Consumer|South Korea|Asia Pacific|Technology|Tablet Stand Holder|7|2613|15|15547|1474|4013|PayPal|
|ORD\-10003|2023\-07\-09|Priya Martinez|Consumer|Japan|Asia Pacific|Furniture|Desk Organizer Set|3|5314|15|13551|1488|2498|PayPal|
|ORD\-10004|2024\-01\-29|Amir Garcia|Corporate|South Africa|Middle East & Africa|Technology|Mechanical Gaming Keyboard|12|1505|20|14448|378|4137|Credit Card|
|ORD\-10005|2024\-03\-05|Chen Patel|Home Office|Canada|North America|Office Supplies|Ballpoint Pen Pack 12|1|1292|10|1163|583|\-1|Credit Card|

#### Ventas regionales por categoría
```sql
SELECT
	Region,
	Product_Category,
	FORMAT(SUM(Total_Sales), '$ #,###') Sales_Segment,
	FORMAT(SUM(Profit), '$ #,###') Profit_Segment
FROM Global_Sales
GROUP BY Region, Product_Category
ORDER BY SUM(Profit) DESC
```
|Region|Product\_Category|Sales\_Segment|Profit\_Segment|
|---|---|---|---|
|Europe|Furniture|$ 6\.862\.903|$ 2\.406\.099|
|North America|Furniture|$ 6\.643\.179|$ 2\.271\.706|
|Asia Pacific|Furniture|$ 5\.405\.197|$ 1\.678\.885|
|Europe|Technology|$ 3\.300\.160|$ 1\.218\.099|
|North America|Technology|$ 3\.405\.592|$ 1\.183\.653|
|Asia Pacific|Technology|$ 2\.865\.758|$ 1\.063\.858|
|Europe|Clothing & Accessories|$ 1\.633\.565|$ 696\.583|
|Middle East & Africa|Furniture|$ 1\.798\.766|$ 627\.402|
|South America|Furniture|$ 1\.903\.818|$ 614\.926|
|North America|Clothing & Accessories|$ 1\.350\.385|$ 611\.173|

#### Ranking de países por margen dentro de cada región — CTE + Window Function
```sql
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
```
> El CTE permite calcular el margen de venta promedio por país como paso previo, y la Window Function `RANK()` asigna un ranking a los paises dentro de cada región en base al margen.

|Ranking|Region|Country|Total\_Sales|Total\_Profit|Margen\_Pct|
|---|---|---|---|---|---|
|1|Asia Pacific|India|$ 1\.570\.397|$ 573\.225|37,0 %|
|2|Asia Pacific|China|$ 2\.218\.602|$ 750\.356|34,0 %|
|3|Asia Pacific|Japan|$ 2\.513\.034|$ 841\.034|33,0 %|
|4|Asia Pacific|South Korea|$ 1\.686\.574|$ 534\.368|32,0 %|
|5|Asia Pacific|Australia|$ 2\.174\.739|$ 676\.152|31,0 %|
|1|Europe|Italy|$ 2\.207\.583|$ 876\.902|40,0 %|
|2|Europe|France|$ 2\.286\.048|$ 852\.139|37,0 %|
|3|Europe|Spain|$ 2\.137\.902|$ 764\.822|36,0 %|
|4|Europe|Germany|$ 2\.602\.693|$ 908\.238|35,0 %|
|5|Europe|United Kingdom|$ 2\.866\.023|$ 977\.240|34,0 %|


#### Ventas acumuladas mensuales y participación anual — Window Function
```sql
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
```
> `SUM(SUM(Total_Sales)) OVER (...)` permite calcular el acumulado y la participación mensual sobre el total anual manteniendo el detalle por mes, operando sobre los valores ya agregados por el GROUP BY.

|Año|Mes|Ventas\_Mes|Ventas\_Acumuladas|Participacion\_Anual|
|---|---|---|---|---|
|2023|1|$ 1\.054\.575|$ 1\.054\.575|7,00 %|
|2023|2|$ 1\.605\.429|$ 2\.660\.004|10,65 %|
|2023|3|$ 1\.451\.106|$ 4\.111\.110|9,63 %|
|2023|4|$ 1\.047\.320|$ 5\.158\.430|6,95 %|
|2023|5|$ 768\.585|$ 5\.927\.015|5,10 %|
|2023|6|$ 1\.522\.186|$ 7\.449\.201|10,10 %|
|2023|7|$ 1\.472\.255|$ 8\.921\.456|9,77 %|
|2023|8|$ 1\.183\.869|$ 10\.105\.325|7,86 %|
|2023|9|$ 921\.493|$ 11\.026\.818|6,12 %|
|2023|10|$ 1\.682\.458|$ 12\.709\.276|11,17 %|
|2023|11|$ 795\.637|$ 13\.504\.913|5,28 %|
|2023|12|$ 1\.564\.115|$ 15\.069\.028|10,38 %|

#### Participación por medio de pago
```sql
SELECT
	Payment_Method,
	FORMAT(SUM(Total_Sales), '$ #,###') Total_Sales,
	FORMAT(
		SUM(Total_Sales) / SUM(SUM(Total_Sales)) OVER(), 
		'P') AS '% Sales'
FROM Global_Sales
GROUP BY Payment_Method
ORDER BY SUM(Total_Sales) DESC
```
|Payment\_Method|Total\_Sales|% Sales|
|---|---|---|
|Credit Card|$ 16\.417\.070|39,24 %|
|PayPal|$ 12\.342\.573|29,50 %|
|Cash on Delivery|$ 6\.719\.273|16,06 %|
|Bank Transfer|$ 6\.361\.748|15,20 %|

---

## Dashboard Power BI

El dashboard está estructurado en dos páginas con las métricas principales para realizar un análisis de las ventas globales de la empresa

[Ver Dashboard en Power BI](https://app.powerbi.com/view?r=eyJrIjoiZGRkNTcxODUtNTAyOC00N2I0LWI4YzUtYjY3MzM0Njc1ZWUyIiwidCI6ImZjZDlhYmQ4LWRmY2QtNGExYS1iNzE5LThhMTNhY2ZkNWVkOSIsImMiOjR9&pageName=351cb590cbbdbb5c4256)

### Página 1 — Resumen Comercial Global
[Ver Página 1](Dashboard_Comercial/Images/Dashboard_1.png)

*¿cómo está el negocio en términos de ventas y rentabilidad? ¿Cuáles son nuestros mejores productos y sectores geográficos?*

- **Mapa de burbujas:** distribución de ventas por región
- **Gráfico de líneas:** ventas mensual por región
- **Gráfico de barras:** Top 10 productos por ventas y utilidad
- **Tarjetas:** Ventas totales, utilidad, márgen de utilidad y ticket promedio
- **Filtros:** rango de fechas y categoría de producto

### Página 2 — Ventas por país
[Ver Página 2](Dashboard_Comercial/Images/Dashboard_2.png)

*¿qué países son más rentables y cómo evolucionan respecto a períodos anteriores?*

- **Tabla comparativa por país:** ventas actuales vs mes y año anterior con variación porcentual
- **Scatter plot:** relación entre ventas y utilidad por país
- **Medidores de margen:** margen de contribución por categoría de producto
- **Filtros:** región, año y mes

### Medidas DAX destacadas

```dax
-- Margen de contribución global
Margen = DIVIDE(SUM('Global_Sales'[Profit]), SUM('Global_Sales'[Total_Sales]))
 
-- Ticket promedio por transacción
Ticket Promedio = SUM('Global_Sales'[Total_Sales]) / COUNT('Global_Sales'[Order_ID])
 
-- Ventas período anterior (mes y año)
Ventas -1M = CALCULATE(SUM('Global_Sales'[Total_Sales]), DATEADD(Calendario[Fecha], -1, MONTH))
Ventas -1Y = CALCULATE(SUM('Global_Sales'[Total_Sales]), SAMEPERIODLASTYEAR(Calendario[Fecha]))
 
-- Variación absoluta respecto a períodos anteriores
Variacion Ventas Mes = SUM('Global_Sales'[Total_Sales]) - [Ventas -1M]
Variacion Ventas Año = SUM('Global_Sales'[Total_Sales]) - [Ventas -1Y]
 
-- Variación porcentual respecto a períodos anteriores
% Ventas -1M = DIVIDE([Variacion Ventas Mes], [Ventas -1M], 0)
% Ventas -1Y = DIVIDE([Variacion Ventas Año], [Ventas -1Y], 0)
```

---

## Conclusiones del análisis
- **Norte America, Asia y Europa** concentran el mayor volumen de ventas, en comparación con Sudamérica y África con una menor participación.
- **Standing Desk Converter y Ergonomic Office Chair** lideran tanto en ventas como utilidad entre todos los productos.
- **Clothing & Accessories** presenta el margen de contribución más alto (44%), mientras que Office Supplies muestra el menor (16%).
- **Furniture** es la categoría con mayores ventas, superando por el doble a Technology, pero es menos redituable en términos porcentuales dado que cuenta con un margen de 33.6% comparado a un 36.43% 
  
Debido a la falta de coherencia en los datos no se pueden entregar conclusiones contundentes en variaciones de ventas debido a la alta dispersión de los datos, esto se debe a que se trata de un dataset ficticio, entendiendose que en condiciones con datos reales sería más significativo ver la evolución en las ventas de los países

---

## Créditos

Datos obtenidos de Kaggle,  "Global E-Commerce Sales & Customer Data" por Muhammad Aammar Tufail.

---

## 👤 Autor

**Walter Bravo Escalona**  
Ingeniero Comercial — Universidad de La Frontera  
[LinkedIn](https://www.linkedin.com/in/walter-bravo) · [GitHub](https://github.com/WalterB304)
