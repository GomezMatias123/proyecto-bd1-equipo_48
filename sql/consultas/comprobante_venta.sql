USE DragabulK_TCG; 
GO

-- Comprobantes (TODOS LOS CLIENTES)

SELECT 
    COMPRA.ID_compra AS [Nro Comprobante],
    FORMAT(COMPRA.Fecha, 'dd/MM/yyyy') AS [Fecha Emisión],
    CONCAT(CLIENTE.apellido, ', ', CLIENTE.nombre) AS [Comprador / Cliente],
    CONCAT(EMPLEADO.apellido, ', ', EMPLEADO.nombre) AS [Vendedor AT],
    METODODEPAGO.nombre AS [Forma de Pago],
    PRODUCTO.Tipo AS [Categoría],
    PRODUCTO.Edicion AS [Colección TCG],
    DETALLE_COMPRA.Cantidad AS [Cant.],
    DETALLE_COMPRA.Precio_unitario AS [Precio Unitario],
    
    -- 1. subtotal por renglón (Precio * Cantidad)
    (DETALLE_COMPRA.Cantidad * DETALLE_COMPRA.Precio_unitario) AS [Sub-Total por Renglón],
    
    -- 2. total acumulado por comprobante
    SUM(DETALLE_COMPRA.Cantidad * DETALLE_COMPRA.Precio_unitario) OVER(
        PARTITION BY COMPRA.ID_compra
    ) AS [Total Acumulado Comprobante]

FROM COMPRA
INNER JOIN DETALLE_COMPRA ON COMPRA.ID_compra = DETALLE_COMPRA.ID_compra
INNER JOIN PRODUCTO ON DETALLE_COMPRA.ID_producto = PRODUCTO.ID_producto
INNER JOIN CLIENTE ON COMPRA.ID_cliente = CLIENTE.ID_cliente
INNER JOIN EMPLEADO ON COMPRA.ID_empleado = EMPLEADO.ID_empleado
INNER JOIN METODODEPAGO ON COMPRA.ID_metodo_pago = METODODEPAGO.ID_metodo_pago
--WHERE COMPRA.ID_compra = 2; -- Si se desea el comprobante de un cliente (sacar ; de arriba)
ORDER BY COMPRA.ID_compra, PRODUCTO.ID_producto;