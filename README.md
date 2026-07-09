# Personal-Portfolio
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
Personal-Portfolio/
│
├── Data/
│   └── Global_Sales.csv               # Dataset 
│
├── SQL/
│   └── Global Sales.sql               # Consultas de exploración y análisis inicial
│
├── Dashboard/
│   └── Global_Sales_Dashboard.pbix    # Dashboard de Power BI
│
└── README.md
```

---

## Herramientas utilizadas

| Herramienta | Uso |
|---|---|
| SQL Server (SSMS) | Exploración inicial de datos |
| Power BI Desktop | Modelado, DAX y visualización |

---

## Exploración en SQL Server

La exploración inicial se realizó directamente en SSMS antes de conectar Power BI, validando los datos, respondiendo preguntas de negocio con queries y luego exponiendo los resultados al dashboard.

### Consultas principales

#### Vista inicial del dataset
```sql
SELECT TOP 25 *
FROM Global_Sales

SELECT COUNT(Order_ID) N_filas
FROM Global_Sales
```

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

---

## Dashboard Power BI

El dashboard está estructurado en dos páginas con las métricas principales para realizar un análisis de las ventas globales de la empresa

### Página 1 — Resumen Comercial Global

Orientada a responder: *¿cómo está el negocio en términos de ventas, rentabilidad y distribución geográfica?*

- **Mapa de burbujas:** distribución de ventas por región
- **Gráfico de líneas:** tendencia de ventas mensual por región (2023–2025)
- **Gráfico de barras:** Top productos por ventas y utilidad
- **Gráfico de dona:** participación por método de pago
- **Filtros:** rango de fechas y categoría de producto

### Página 2 — Análisis por Mercado

Orientada a responder: *¿qué países son más rentables y cómo evolucionan respecto a períodos anteriores?*

- **Tabla comparativa por país:** ventas actuales vs mes anterior y año anterior con variación porcentual
- **Scatter plot:** relación entre ventas y utilidad por país, con línea de tendencia
- **Medidores de margen:** margen de contribución por categoría de producto
- **Filtros:** región, año y mes

### Medidas DAX destacadas

```dax
-- Ventas mes anterior
Ventas Mes Anterior = 
CALCULATE(
    SUM(Global_Sales[Total_Sales]),
    DATEADD(Calendario[Date], -1, MONTH)
)

-- Crecimiento porcentual respecto al mes anterior
Crecimiento % vs Mes Anterior = 
DIVIDE(
    SUM(Global_Sales[Total_Sales]) - [Ventas Mes Anterior],
    [Ventas Mes Anterior],
    0
)

-- Margen de contribución por categoría
Margen Clothing = 
DIVIDE(
    CALCULATE(SUM(Global_Sales[Profit]), Global_Sales[Product_Category] = "Clothing & Accessories"),
    CALCULATE(SUM(Global_Sales[Total_Sales]), Global_Sales[Product_Category] = "Clothing & Accessories")
)
```

---

## Conclusiones del análisis
- **North America y Europe** concentran el mayor volumen de ventas, pero mercados de Asia Pacific muestran márgenes comparables con menor volumen.
- **Standing Desk Converter y Ergonomic Office Chair** lideran en ventas y utilidad dentro de la categoría Furniture.
- **Clothing & Accessories** presenta el margen de contribución más alto (0.44), mientras que Office Supplies muestra el menor (0.16).
- La distribución por método de pago es relativamente equilibrada, con leve predominancia de Credit Card (39.2%).

---

## Créditos
Datos obtenidos de Kaggle "Global E-Commerce Sales & Customer Data" por Muhammad Aammar Tufail..

---

## 👤 Autor

**Walter Bravo Escalona**  
Ingeniero Comercial — Universidad de La Frontera  
[LinkedIn](https://www.linkedin.com/in/walter-bravo) · [GitHub](https://github.com/WalterB304)
