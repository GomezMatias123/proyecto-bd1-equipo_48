-- ============================================================================
-- PROYECTO INTEGRADOR: DragabulK_TCG
-- ETAPA V: Optimización de consultas a través de índices
-- Alumno: Emiliano (Equipo 48)
-- Base de Datos: DragabulK_TCG
-- ============================================================================

USE DragabulK_TCG;
GO

-- ============================================================================
-- PARTE 1: Creación de la tabla de pruebas (COMPRA_HISTORICA)
-- Adaptada del modelo relacional DragabulK_TCG (Tabla COMPRA)
-- ============================================================================

IF OBJECT_ID('COMPRA_HISTORICA', 'U') IS NOT NULL
DROP TABLE COMPRA_HISTORICA;
GO

CREATE TABLE COMPRA_HISTORICA
(
ID_compra BIGINT IDENTITY(1,1) NOT NULL,
Fecha DATE NOT NULL,
Monto_Total DECIMAL(12,2) NOT NULL,
ID_cliente INT NOT NULL,
ID_empleado INT NOT NULL,
ID_metodo_pago INT NOT NULL,
CONSTRAINT PK_COMPRA_HISTORICA PRIMARY KEY NONCLUSTERED (ID_compra)
);
GO

-- ============================================================================
-- PARTE 2: Carga masiva de datos (1.000.000 de registros)
-- Generación sintética de compras masivas en la tienda TCG
-- ============================================================================

SET NOCOUNT ON;
GO

PRINT 'Iniciando la carga masiva de 1.000.000 de registros en COMPRA_HISTORICA...';

WITH Numeros AS
(
SELECT TOP (1000000)
ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n
FROM sys.objects a
CROSS JOIN sys.objects b
CROSS JOIN sys.objects c
)
INSERT INTO COMPRA_HISTORICA (Fecha, Monto_Total, ID_cliente, ID_empleado, ID_metodo_pago)
SELECT
-- Fechas aleatorias distribuidas en un rango de 5 años (desde 2020-01-01)
DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 1825, '2020-01-01') AS Fecha,
-- Monto de compra entre $500 y $150.000 (precios típicos de cartas/boosters TCG)
CAST(ROUND((RAND(CHECKSUM(NEWID())) * 149500) + 500, 2) AS DECIMAL(12,2)) AS Monto_Total,
-- IDs sintéticos referenciales de clientes, empleados y métodos de pago
(ABS(CHECKSUM(NEWID())) % 10000) + 1 AS ID_cliente,
(ABS(CHECKSUM(NEWID())) % 50) + 1 AS ID_empleado,
(ABS(CHECKSUM(NEWID())) % 5) + 1 AS ID_metodo_pago
FROM Numeros;
GO

-- Verificación de volumen cargado
SELECT COUNT(*) AS CantidadRegistrosCargados FROM COMPRA_HISTORICA;
GO

-- ============================================================================
-- PARTE 3: Consulta base sin índices sobre el filtro Fecha
-- Medición de rendimiento (Table Scan / Heap Scan)
-- ============================================================================

-- Activación de estadísticas de tiempo de CPU y lecturas de E/S
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

PRINT '--- PRUEBA 1: Consulta sin índices (Table Scan) ---';

SELECT
ID_compra,
Fecha,
Monto_Total,
ID_cliente,
ID_metodo_pago
FROM COMPRA_HISTORICA
WHERE Fecha BETWEEN '2023-01-01' AND '2023-03-31';
GO

-- Desactivar estadísticas momentáneamente
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ============================================================================
-- PARTE 4: Creación de Índice sobre el campo de filtrado (Fecha)
-- Re-ejecución y análisis con Index Seek / Key Lookup
-- ============================================================================

-- Limpieza preventiva de índices previos
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_COMPRA_HISTORICA_Fecha' AND object_id = OBJECT_ID('COMPRA_HISTORICA'))
DROP INDEX IX_COMPRA_HISTORICA_Fecha ON COMPRA_HISTORICA;
GO

PRINT 'Creando índice simple por columna Fecha...';
CREATE NONCLUSTERED INDEX IX_COMPRA_HISTORICA_Fecha
ON COMPRA_HISTORICA (Fecha);
GO

-- Activar métricas
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

PRINT '--- PRUEBA 2: Consulta con Índice sobre Fecha (Index Seek + Key Lookup) ---';

SELECT
ID_compra,
Fecha,
Monto_Total,
ID_cliente,
ID_metodo_pago
FROM COMPRA_HISTORICA WITH(INDEX(IX_COMPRA_HISTORICA_Fecha))
WHERE Fecha BETWEEN '2023-01-01' AND '2023-03-31';
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- ============================================================================
-- PARTE 5: Eliminación del índice anterior
-- Preparación del escenario de Cobertura Completa
-- ============================================================================

DROP INDEX IX_COMPRA_HISTORICA_Fecha ON COMPRA_HISTORICA;
GO

-- ============================================================================
-- PARTE 6: Creación de Índice con Cobertura (Covering Index - INCLUDE)
-- Cobertura total de columnas consultadas para eliminar Key Lookups
-- ============================================================================

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_COMPRA_HISTORICA_Fecha_Cobertura' AND object_id = OBJECT_ID('COMPRA_HISTORICA'))
DROP INDEX IX_COMPRA_HISTORICA_Fecha_Cobertura ON COMPRA_HISTORICA;
GO

PRINT 'Creando índice con cobertura (INCLUDE) para optimizar la consulta...';
CREATE NONCLUSTERED INDEX IX_COMPRA_HISTORICA_Fecha_Cobertura
ON COMPRA_HISTORICA (Fecha)
INCLUDE (ID_compra, Monto_Total, ID_cliente, ID_metodo_pago);
GO

-- Activar métricas
SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

PRINT '--- PRUEBA 3: Consulta con Índice de Cobertura (Index Seek Puro) ---';

SELECT
ID_compra,
Fecha,
Monto_Total,
ID_cliente,
ID_metodo_pago
FROM COMPRA_HISTORICA
WHERE Fecha BETWEEN '2023-01-01' AND '2023-03-31';
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO