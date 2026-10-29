## Explicacion 

Obtener el total de ventas realizadas **por cada vendedor** y **por cada categoría de producto** dentro de un rango de fechas, usando funciones de agregación (`COUNT`, `SUM`) y agrupamiento (`GROUP BY`).

## Elementos utilizados

| Elemento | Para qué se usa |
|---|---|
| `GROUP BY` | Agrupa las filas por vendedor o por categoría, para calcular un resultado por grupo |
| `SUM()` | Suma unidades vendidas y montos recaudados |
| `COUNT(DISTINCT ...)` | Cuenta ventas sin repetir: una compra con varios productos aparece en varias filas del detalle, pero debe contar una sola vez |
| `INNER JOIN` | Une las tablas necesarias para llegar del vendedor o del producto hasta el detalle de la venta |
| `WHERE ... BETWEEN` | Filtra las compras por rango de fechas (los extremos están incluidos) |
| `ORDER BY ... DESC` | Ordena de mayor a menor recaudación |

El monto de cada línea se calcula como `Cantidad * Precio_unitario`. Se usa `Precio_unitario` del detalle y no `Precio_actual` del producto, porque es el precio que se cobró en el momento de la venta.
