USE DragabulK_TCG;
GO


-- Total de ventas realizadas por cada VENDEDOR


SELECT 
    EMPLEADO.ID_empleado AS [ID Vendedor],
    CONCAT(EMPLEADO.apellido, ', ', EMPLEADO.nombre) AS [Vendedor],
    COUNT(DISTINCT COMPRA.ID_compra) AS [Cantidad de Ventas],
    SUM(DETALLE_COMPRA.Cantidad) AS [Total Unidades Vendidas],
    SUM(DETALLE_COMPRA.Cantidad * DETALLE_COMPRA.Precio_unitario) AS [Monto Total Recaudado]
FROM EMPLEADO
INNER JOIN COMPRA ON EMPLEADO.ID_empleado = COMPRA.ID_empleado
INNER JOIN DETALLE_COMPRA ON COMPRA.ID_compra = DETALLE_COMPRA.ID_compra
WHERE COMPRA.Fecha BETWEEN '2026-01-01' AND '2026-12-31' -- Filtro por rango de fechas
GROUP BY 
    EMPLEADO.ID_empleado, 
    EMPLEADO.apellido, 
    EMPLEADO.nombre
ORDER BY [Monto Total Recaudado] DESC;
GO


-- Total de ventas por CATEGORÍA DE PRODUCTO

SELECT 
    PRODUCTO.Tipo AS [Categoría],
    COUNT(DISTINCT COMPRA.ID_compra) AS [Transacciones Involucradas],
    SUM(DETALLE_COMPRA.Cantidad) AS [Unidades Vendidas],
    SUM(DETALLE_COMPRA.Cantidad * DETALLE_COMPRA.Precio_unitario) AS [Recaudación Total]
FROM PRODUCTO
INNER JOIN DETALLE_COMPRA ON PRODUCTO.ID_producto = DETALLE_COMPRA.ID_producto
INNER JOIN COMPRA ON DETALLE_COMPRA.ID_compra = COMPRA.ID_compra
WHERE COMPRA.Fecha BETWEEN '2026-01-01' AND '2026-12-31' -- Filtro por rango de fechas
GROUP BY PRODUCTO.Tipo
ORDER BY [Recaudación Total] DESC;
GO