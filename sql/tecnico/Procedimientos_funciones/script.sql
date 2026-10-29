USE DragabulK_TCG;
GO

-- ============================================================
-- 0. LIMPIEZA: deja la tabla PRODUCTO con los datos de prueba determinados (sirve para re ejectuar el codigo para volver a realizar las pruebas)
-- ============================================================
DELETE FROM PRODUCTO WHERE ID_producto > 8;
GO

-- ============================================================
-- 1. PROCEDIMIENTOS: sp_Producto_Insertar, _Modificar, _Eliminar
-- ============================================================
CREATE OR ALTER PROCEDURE sp_Producto_Insertar
    @Edicion          VARCHAR(100),
    @Precio_actual    INT,
    @Stock_disponible INT,
    @Tipo             VARCHAR(50),
    @ID_producto      INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Precio_actual <= 0
        THROW 50001, 'El precio debe ser mayor a 0.', 1;

    IF @Stock_disponible < 0
        THROW 50002, 'El stock no puede ser negativo.', 1;

    IF EXISTS (SELECT 1 FROM PRODUCTO WHERE Edicion = @Edicion AND Tipo = @Tipo)
        THROW 50003, 'Ya existe un producto con esa edicion y tipo.', 1;

    SELECT @ID_producto = ISNULL(MAX(ID_producto), 0) + 1 FROM PRODUCTO;

    INSERT INTO PRODUCTO (ID_producto, Edicion, Precio_actual, Stock_disponible, Tipo)
    VALUES (@ID_producto, @Edicion, @Precio_actual, @Stock_disponible, @Tipo);
END
GO


-- Caso correcto
DECLARE @nuevoID INT;
EXEC sp_Producto_Insertar
    @Edicion = 'Perfect Order', @Precio_actual = 450000,
    @Stock_disponible = 4, @Tipo = 'Booster Box',
    @ID_producto = @nuevoID OUTPUT;
SELECT * FROM PRODUCTO WHERE ID_producto = @nuevoID;
GO

-- Caso con error (precio negativo)
DECLARE @id INT;
EXEC sp_Producto_Insertar
    @Edicion = 'Test', @Precio_actual = -5,
    @Stock_disponible = 1, @Tipo = 'Sobres',
    @ID_producto = @id OUTPUT;
GO

---------------------------------------------

CREATE OR ALTER PROCEDURE sp_Producto_Modificar
    @ID_producto      INT,
    @Edicion          VARCHAR(100),
    @Precio_actual    INT,
    @Stock_disponible INT,
    @Tipo             VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE ID_producto = @ID_producto)
        THROW 50004, 'El producto no existe.', 1;

    IF @Precio_actual <= 0
        THROW 50001, 'El precio debe ser mayor a 0.', 1;

    IF @Stock_disponible < 0
        THROW 50002, 'El stock no puede ser negativo.', 1;

    IF EXISTS (SELECT 1 FROM PRODUCTO
            WHERE Edicion = @Edicion AND Tipo = @Tipo
            AND ID_producto <> @ID_producto)
        THROW 50003, 'Ya existe otro producto con esa edicion y tipo.', 1;

    UPDATE PRODUCTO
    SET Edicion          = @Edicion,
        Precio_actual    = @Precio_actual,
        Stock_disponible = @Stock_disponible,
        Tipo             = @Tipo
    WHERE ID_producto = @ID_producto;
END
GO

-- Caso correcto: subir precio y stock del producto 9
EXEC sp_Producto_Modificar
    @ID_producto = 9, @Edicion = 'Perfect Order',
    @Precio_actual = 460000, @Stock_disponible = 6, @Tipo = 'Booster Box';
SELECT * FROM PRODUCTO WHERE ID_producto = 9;
GO

-- Caso con error: producto inexistente
EXEC sp_Producto_Modificar
    @ID_producto = 999, @Edicion = 'X',
    @Precio_actual = 1000, @Stock_disponible = 1, @Tipo = 'Sobres';
GO

-----------------------------------------
CREATE OR ALTER PROCEDURE sp_Producto_Eliminar
    @ID_producto INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE ID_producto = @ID_producto)
        THROW 50004, 'El producto no existe.', 1;

    IF EXISTS (SELECT 1 FROM DETALLE_COMPRA WHERE ID_producto = @ID_producto)
        THROW 50005, 'No se puede eliminar: el producto tiene ventas registradas.', 1;

    IF EXISTS (SELECT 1 FROM REPOSICION_PRODUCTOS WHERE ID_producto = @ID_producto)
        THROW 50006, 'No se puede eliminar: el producto tiene reposiciones registradas.', 1;

    DELETE FROM PRODUCTO
    WHERE ID_producto = @ID_producto;
END
GO

-- Caso correcto: crear un producto descartable y eliminarlo
DECLARE @idTemp INT;
EXEC sp_Producto_Insertar
    @Edicion = 'Producto Temporal', @Precio_actual = 1000,
    @Stock_disponible = 1, @Tipo = 'Sobres',
    @ID_producto = @idTemp OUTPUT;

SELECT 'Antes del DELETE' AS Momento, * FROM PRODUCTO WHERE ID_producto = @idTemp;

EXEC sp_Producto_Eliminar @ID_producto = @idTemp;

SELECT COUNT(*) AS Filas_restantes FROM PRODUCTO WHERE ID_producto = @idTemp;
GO

-- Caso con error: producto con ventas (el 1 aparece en DETALLE_COMPRA)
EXEC sp_Producto_Eliminar @ID_producto = 1;
GO  

-- Caso con error: producto inexistente
EXEC sp_Producto_Eliminar @ID_producto = 999;
GO

-- ============================================================
-- 2. INSERT directos
-- ============================================================
INSERT INTO PRODUCTO (ID_producto, Edicion, Precio_actual, Stock_disponible, Tipo)
VALUES
    (10, 'Surging Sparks',      260000, 8,  'Elite Trainer Box'),
    (11, 'Surging Sparks',      16500,  60, 'Sobres'),
    (12, 'Prismatic Evolutions', 120000, 6,  'Collection Box');

SELECT * FROM PRODUCTO WHERE ID_producto BETWEEN 10 AND 12;
GO

-- ============================================================
-- 3. INSERT invocando sp_Producto_Insertar
-- ============================================================
DECLARE @id INT;

EXEC sp_Producto_Insertar
    @Edicion = 'Phantasmal Flames', @Precio_actual = 430000,
    @Stock_disponible = 4, @Tipo = 'Booster Box', @ID_producto = @id OUTPUT;

EXEC sp_Producto_Insertar
    @Edicion = 'Ascended heroes', @Precio_actual = 17500,
    @Stock_disponible = 70, @Tipo = 'Sobres', @ID_producto = @id OUTPUT;

EXEC sp_Producto_Insertar
    @Edicion = 'Mega Dream EX', @Precio_actual = 135000,
    @Stock_disponible = 5, @Tipo = 'Collection Box', @ID_producto = @id OUTPUT;

SELECT * FROM PRODUCTO WHERE ID_producto >= 9;
GO

-- ============================================================
-- 4. UPDATE Y DELETE INVOCANDO LOS PROCEDIMIENTOS
-- ============================================================

-- Estado ANTES
SELECT 'ANTES' AS Momento, * FROM PRODUCTO WHERE ID_producto BETWEEN 10 AND 15;

-- UPDATE 1: producto 11, sube el precio de 16500 a 18000
EXEC sp_Producto_Modificar
    @ID_producto = 11, @Edicion = 'Surging Sparks',
    @Precio_actual = 18000, @Stock_disponible = 60, @Tipo = 'Sobres';

-- UPDATE 2: producto 14, repone stock de 70 a 120
EXEC sp_Producto_Modificar
    @ID_producto = 14, @Edicion = 'Ascended heroes',
    @Precio_actual = 17500, @Stock_disponible = 120, @Tipo = 'Sobres';

-- DELETE: productos 12 y 15
EXEC sp_Producto_Eliminar @ID_producto = 12;
EXEC sp_Producto_Eliminar @ID_producto = 15;

-- Estado DESPUES
SELECT 'DESPUES' AS Momento, * FROM PRODUCTO WHERE ID_producto BETWEEN 10 AND 15;
GO


-- ============================================================
-- 5.FUNCIONES ALMACENADAS: fn_TotalCompra, fn_TotalConDescuento, fn_ProductosStockBajo
-- ============================================================


CREATE OR ALTER FUNCTION dbo.fn_TotalCompra (@ID_compra INT)
RETURNS INT
AS
BEGIN
    DECLARE @total INT;

    SELECT @total = ISNULL(SUM(Precio_unitario * Cantidad), 0)
    FROM DETALLE_COMPRA
    WHERE ID_compra = @ID_compra;

    RETURN @total;
END
GO


CREATE OR ALTER FUNCTION dbo.fn_TotalConDescuento (@ID_compra INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @total     INT = dbo.fn_TotalCompra(@ID_compra);
    DECLARE @descuento INT;

    SELECT @descuento = s.Descuento
    FROM COMPRA c
    JOIN SOCIO s ON s.ID_cliente = c.ID_cliente
    WHERE c.ID_compra = @ID_compra;

    SET @descuento = ISNULL(@descuento, 0);   -- si no es socio, 0%

    RETURN @total * (100 - @descuento) / 100.0;
END
GO


CREATE OR ALTER FUNCTION dbo.fn_ProductosStockBajo (@umbral INT)
RETURNS TABLE
AS
RETURN
(
    SELECT ID_producto, Edicion, Tipo, Stock_disponible
    FROM PRODUCTO
    WHERE Stock_disponible <= @umbral
);
GO



SELECT ID_compra, Fecha,
    dbo.fn_TotalCompra(ID_compra)      AS Total,
    dbo.fn_TotalConDescuento(ID_compra) AS Total_con_descuento
FROM COMPRA;
GO


SELECT * FROM dbo.fn_ProductosStockBajo(5);
GO
-- ============================================================
-- 6.COMPARACION DE EFICIENCIA - Parte A: INSERT directo vs procedimiento
-- ============================================================

-- Prueba 1: 1000 INSERT directos
DECLARE @i INT = 1;
DECLARE @t0 DATETIME2 = SYSDATETIME();

WHILE @i <= 1000
BEGIN
    INSERT INTO PRODUCTO (ID_producto, Edicion, Precio_actual, Stock_disponible, Tipo)
    SELECT ISNULL(MAX(ID_producto), 0) + 1,
        'BenchDirecto ' + CAST(@i AS VARCHAR(10)), 1000, 10, 'Sobres'
    FROM PRODUCTO;

    SET @i += 1;
END

SELECT 'INSERT directo' AS Metodo,
    DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) AS Milisegundos;
GO

DELETE FROM PRODUCTO WHERE Edicion LIKE 'Bench%';
GO

-- Prueba 2: 1000 llamadas a sp_Producto_Insertar
DECLARE @i INT = 1;
DECLARE @id INT;
DECLARE @ed VARCHAR(100);
DECLARE @t0 DATETIME2 = SYSDATETIME();

WHILE @i <= 1000
BEGIN
    SET @ed = 'BenchProc ' + CAST(@i AS VARCHAR(10));
    EXEC sp_Producto_Insertar
        @Edicion = @ed, @Precio_actual = 1000,
        @Stock_disponible = 10, @Tipo = 'Sobres', @ID_producto = @id OUTPUT;

    SET @i += 1;
END

SELECT 'Procedimiento' AS Metodo,
    DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) AS Milisegundos;
GO

-- Limpieza: borra todas las filas de prueba
DELETE FROM PRODUCTO WHERE Edicion LIKE 'Bench%';
SELECT COUNT(*) AS Filas_Bench_restantes FROM PRODUCTO WHERE Edicion LIKE 'Bench%';
GO

-- ============================================================
-- 7.COMPARACION DE EFICIENCIA - Parte B: funcion vs consulta directa
-- ============================================================

-- Prueba 1: 5000 llamadas a la funcion
DECLARE @i INT = 1;
DECLARE @total INT;
DECLARE @t0 DATETIME2 = SYSDATETIME();

WHILE @i <= 5000
BEGIN
    SET @total = dbo.fn_TotalCompra(3);
    SET @i += 1;
END

SELECT 'Funcion fn_TotalCompra' AS Metodo,
    DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) AS Milisegundos;
GO

-- Prueba 2: 5000 veces la consulta directa equivalente
DECLARE @i INT = 1;
DECLARE @total INT;
DECLARE @t0 DATETIME2 = SYSDATETIME();

WHILE @i <= 5000
BEGIN
    SELECT @total = ISNULL(SUM(Precio_unitario * Cantidad), 0)
    FROM DETALLE_COMPRA
    WHERE ID_compra = 3;

    SET @i += 1;
END

SELECT 'Consulta directa' AS Metodo,
    DATEDIFF(MILLISECOND, @t0, SYSDATETIME()) AS Milisegundos;
GO