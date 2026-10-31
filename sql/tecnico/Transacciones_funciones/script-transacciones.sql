
-- PROYECTO DRAGABULK - ETAPA V: MANEJO DE TRANSACCIONES
-- TEMA: PROCESO DE VENTA REAL CON VALIDACIÓN DE STOCK

USE DragabulK_TCG;
GO

SET NOCOUNT ON;

-- PRUEBA 1: DEMOSTRACIÓN CORRECTA (STOCK SUFICIENTE)
-- Escenario: Se compran 5 sobres de 'Pitch Black' (ID 2). Como hay unidades en stock, la transacción ocurre exitosamente.

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @id_compra_ok INT;                 -- ID dinámico seguro
    DECLARE @id_producto_ok INT = 2;           -- Sobres Pitch Black
    DECLARE @id_empleado_ok INT = 1;           -- LUCRECIA RAMBAUDI
    DECLARE @id_metodo_ok INT = 1;             -- Efectivo
    DECLARE @id_cliente_ok INT = 1;            -- MAGNO ISLER
    DECLARE @cantidad_ok INT = 5;              -- Compra normal de 5 unidades
    
    DECLARE @stock_actual_ok INT;

    -- Cálculo de ID Dinámico para evitar colisiones de clave primaria
    SELECT @id_compra_ok = ISNULL(MAX(ID_compra), 0) + 1 FROM COMPRA;

    -- 1. Consultamos el inventario actual de la base de datos
    SELECT @stock_actual_ok = Stock_disponible 
    FROM PRODUCTO 
    WHERE ID_producto = @id_producto_ok;

    -- 2. Control del stock
    IF @stock_actual_ok < @cantidad_ok
    BEGIN
        PRINT '-> ERROR: Stock insuficiente para realizar la venta.';
        ROLLBACK TRANSACTION;
        RETURN;
    END
    ELSE
    BEGIN
        -- A) Insertamos en la tabla COMPRA
        INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente)
        VALUES (@id_compra_ok, @id_empleado_ok, @id_metodo_ok, @id_cliente_ok);

        -- B) Insertamos en la tabla DETALLE_COMPRA
        INSERT INTO DETALLE_COMPRA (Precio_unitario, Cantidad, ID_compra, ID_producto)
        VALUES (17000, @cantidad_ok, @id_compra_ok, @id_producto_ok);

        -- C) Descontamos el stock de la tabla PRODUCTO
        UPDATE PRODUCTO
        SET Stock_disponible = Stock_disponible - @cantidad_ok
        WHERE ID_producto = @id_producto_ok;

        -- Cerramos de forma segura guardando todo en el disco
        COMMIT TRANSACTION;
        PRINT '### [PRUEBA 1] ÉXITO: Venta registrada con el ID Seguro: ' + CAST(@id_compra_ok AS VARCHAR(10)) + ' ###';
    END
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'Error crítico en la venta (Prueba 1).';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- Consultas de verificación dinámicas para la Prueba 1:
DECLARE @UltimaCompra INT;
SELECT @UltimaCompra = MAX(ID_compra) FROM COMPRA;

SELECT 'COMPRA REGISTRADA' AS Registro, * FROM COMPRA WHERE ID_compra = @UltimaCompra;
SELECT 'DETALLE REGISTRADO' AS Registro, * FROM DETALLE_COMPRA WHERE ID_compra = @UltimaCompra;
SELECT 'STOCK POST-VENTA' AS Control, ID_producto, Stock_disponible FROM PRODUCTO WHERE ID_producto = 2; 
GO

-- PRUEBA 2: DEMOSTRACIÓN INCORRECTA (ATOMICIDAD POR ERROR 1/0)
-- Escenario: Intentamos comprar pero ocurre un error matemático crítico. El sistema corta el código y ejecuta un ROLLBACK total (Atomicidad).

BEGIN TRY
    -- 1. Declaración de variables 
    DECLARE @id_compra_err INT;          
    DECLARE @id_producto_err INT = 2;          
    DECLARE @id_empleado_err INT = 1;          
    DECLARE @id_metodo_err INT = 1;            
    DECLARE @id_cliente_err INT = 1;            
    DECLARE @cantidad_err INT = 5;           
    
    DECLARE @stock_actual_err INT;

    -- Calculamos dinámicamente el ID que sigue para que NO coincida con la Prueba 1
    SELECT @id_compra_err = ISNULL(MAX(ID_compra), 0) + 1 FROM COMPRA;

    SELECT @stock_actual_err = Stock_disponible 
    FROM PRODUCTO 
    WHERE ID_producto = @id_producto_err;

    -- 2. Transacción justo antes de escribir
    BEGIN TRANSACTION;

    -- A) Se inserta la cabecera de la compra
    INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente)
    VALUES (@id_compra_err, @id_empleado_err, @id_metodo_err, @id_cliente_err);

    -- B) Se inserta el detalle de la compra
    INSERT INTO DETALLE_COMPRA (Precio_unitario, Cantidad, ID_compra, ID_producto)
    VALUES (17000, @cantidad_err, @id_compra_err, @id_producto_err);

    -- ERROR INTENCIONAL LUEGO DEL INSERT.
    -- Provocamos una división por cero para reventar el flujo antes del UPDATE de stock
    DECLARE @ForzarError INT = 1 / 0;

    -- C) Descontar stock (Nunca se ejecutará debido al error de arriba)
    UPDATE PRODUCTO
    SET Stock_disponible = Stock_disponible - @cantidad_err
    WHERE ID_producto = @id_producto_err;

    COMMIT TRANSACTION;
    PRINT '### Venta exitosa (No debería aparecer) ###';

END TRY
BEGIN CATCH

    -- 3. El manejo efectivo del error deshace los INSERTS previos de esta prueba
    IF @@TRANCOUNT > 0 
    BEGIN
        ROLLBACK TRANSACTION;
        PRINT '### [PRUEBA 2] CRITERIO EVALUADO: Error provocado exitosamente. ###';
        PRINT '-> Mensaje del Sistema: ' + ERROR_MESSAGE();
        PRINT '-> Resultado: ROLLBACK aplicado. Se evitó la inserción parcial de la Compra ' + CAST(@id_compra_err AS VARCHAR);
    END
END CATCH;
GO

-- Consultas de verificación para la Prueba 2 (Buscamos dinámicamente el ID que falló):
DECLARE @IdFallido INT;
SELECT @IdFallido = ISNULL(MAX(ID_compra), 0) + 1 FROM COMPRA;

SELECT 'COMPRA FALLIDA (Debe dar 0 filas)' AS Registro, * FROM COMPRA WHERE ID_compra = @IdFallido;
SELECT 'DETALLE FALLIDO (Debe dar 0 filas)' AS Registro, * FROM DETALLE_COMPRA WHERE ID_compra = @IdFallido;
SELECT 'STOCK INTACTO' AS Control, ID_producto, Stock_disponible FROM PRODUCTO WHERE ID_producto = 2;
GO


-- =====================================================================
-- IMPLEMENTACIÓN DE TRANSACCIÓN ANIDADA (REPOSICIÓN)
-- =====================================================================
BEGIN TRY
    -- 1. Declaración de variables
    DECLARE @proximo_id_reposicion INT;
    DECLARE @id_proveedor_real INT = 1;     -- Proveedor: 'Devir'
    DECLARE @id_producto_real INT = 2;      -- Producto: Sobres 'Pitch Black'
    DECLARE @telefono_nuevo VARCHAR(20);

    -- 2. ID dinámico
    SELECT @proximo_id_reposicion = ISNULL(MAX(ID_reposicion), 0) + 1 
    FROM REPOSICION_PRODUCTOS;

    -- Generamos un teléfono dinámico basado en el ID para que tampoco duplique
    SET @telefono_nuevo = '3794' + CONVERT(VARCHAR(6), 100000 + @proximo_id_reposicion);

    -- 3. Inicio de transacción principal
    BEGIN TRANSACTION;
    PRINT '-> Iniciando Transacción Principal con el ID Seguro: ' + CAST(@proximo_id_reposicion AS VARCHAR);

    -- Insertamos la reposición con la fecha del sistema temporalmente
    INSERT INTO REPOSICION_PRODUCTOS (Fecha, Cantidad, ID_reposicion, ID_proveedor, ID_producto)
    VALUES (CAST(GETDATE() AS DATE), 100, @proximo_id_reposicion, @id_proveedor_real, @id_producto_real);
    PRINT '-> Paso 1: Ingreso de stock registrado con éxito.';

    -- 4. CREACIÓN DEL PUNTO DE GUARDADO (Inicio de la transacción anidada)
    SAVE TRANSACTION PuntoContactoProveedor;
    PRINT '-> Punto de control "PuntoContactoProveedor" establecido en memoria.';

    -- 5. Intentamos insertar el teléfono dinámico para el Proveedor 1
    INSERT INTO PROVEEDOR_TELEFONO (Telefono, ID_proveedor)
    VALUES (@telefono_nuevo, @id_proveedor_real);

    -- 6. FORZAMOS EL ERROR INTENCIONAL DE INTEGRIDAD (Clave Foránea)
    -- Mandamos un correo asociándolo al ID de proveedor 99999 (que NO existe)
    INSERT INTO PROVEEDOR_EMAIL (Email, ID_proveedor)
    VALUES ('error_test@proveedor.com', 99999);

    -- Di funciona se ejecuta (que no pasará)
    COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    PRINT '### CONTROL DE ERRORES: FALLO EN NIVEL ANIDADO DETECTADO ###';
    PRINT 'Mensaje original del motor: ' + ERROR_MESSAGE();

    IF @@TRANCOUNT > 0
    BEGIN
        PRINT '-> Aplicando ROLLBACK parcial seguro hasta el punto de guardado...';
        -- Deshacemos únicamente el teléfono y el email fallidos
        ROLLBACK TRANSACTION PuntoContactoProveedor;
        
        -- Confirmamos la transacción principal para salvar la reposición de stock
        COMMIT TRANSACTION;
        PRINT '### ÉXITO: Transacción Principal salvada de forma consistente. ###';
        PRINT '-> La reposición quedó guardada en el historial; el contacto erróneo se anuló.';
    END
    ELSE
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT '-> Transacción totalmente anulada.';
    END
END CATCH;
GO

-- Consultas de verificación automáticas de la reposición:
SELECT 'ÚLTIMA REPOSICIÓN GRABADA' AS Estado, * 
FROM REPOSICION_PRODUCTOS 
WHERE ID_reposicion = (SELECT MAX(ID_reposicion) FROM REPOSICION_PRODUCTOS);
GO

SELECT 'HISTORIAL COMPLETO' AS Estado, * FROM REPOSICION_PRODUCTOS ORDER BY ID_reposicion ASC;
GO
