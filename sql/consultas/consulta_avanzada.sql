USE DragabulK_TCG;
GO

-- Socios cuyo gasto total supera el promedio de gasto por cliente

SELECT
    CLIENTE.ID_cliente as [ID Cliente],
    CONCAT(CLIENTE.apellido,', ', CLIENTE.nombre) AS [Socio],
    COUNT(DISTINCT COMPRA.ID_compra) AS [Cant. Compras],
    SUM(DETALLE_COMPRA.Cantidad * DETALLE_COMPRA.Precio_unitario) AS [Gasto Total]
    FROM CLIENTE
    -- Identifica que clientes son socios
    INNER JOIN SOCIO ON CLIENTE.ID_cliente = SOCIO.ID_cliente    
    -- Obtiene las compras de cada cliente
    INNER JOIN COMPRA ON CLIENTE.ID_cliente = COMPRA.ID_cliente
    -- Obtiene productos, cantidades y precios
    INNER JOIN DETALLE_COMPRA ON COMPRA.ID_compra = DETALLE_COMPRA.ID_compra
    GROUP BY CLIENTE.ID_cliente, CLIENTE.apellido, CLIENTE.nombre
    HAVING SUM(DETALLE_COMPRA.Cantidad * DETALLE_COMPRA.Precio_unitario) > (
        SELECT AVG(Total_cliente)
        FROM (
            SELECT SUM(DC.Cantidad * DC.Precio_unitario) AS Total_cliente
            FROM COMPRA C
            INNER JOIN DETALLE_COMPRA DC ON C.ID_compra = DC.ID_compra
            GROUP BY C.ID_cliente
        ) AS Totales
    )
    ORDER BY [Gasto Total] DESC;
