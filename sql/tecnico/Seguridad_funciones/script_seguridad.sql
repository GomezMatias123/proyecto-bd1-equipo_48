USE DragabulK_TCG;
GO

--------------------------------------------------------------------------------
-- Limpieza IDs de prueba antes de las pruebas
--------------------------------------------------------------------------------

SELECT USER_NAME() AS Usuario_actual;   -- debe decir 'dbo'
DELETE FROM dbo.COMPRA WHERE ID_compra IN (900, 901, 902, 903);
GO 
--------------------------------------------------------------------------------
-- 1. LISTADO DE TODAS LAS TABLAS Y VISUALIZACION DE LAS TABLAS
--------------------------------------------------------------------------------
SELECT 
    SCHEMA_NAME(t.schema_id) AS Esquema,
    t.name AS Nombre_Tabla,
    p.rows AS Cantidad_Registros,
    t.create_date AS Fecha_Creacion
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
ORDER BY t.name;
GO

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'SELECT TOP 5 ''' + t.name + N''' AS Tabla, * FROM ' 
            + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name) + N';' + CHAR(13)
FROM sys.tables t
ORDER BY t.name;

EXEC sp_executesql @sql;
GO

--------------------------------------------------------------------------------
-- 2. ASIGNACION DE ROLES DE ADMIN Y LECTOR
--------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_admin')
    CREATE LOGIN usuario_admin WITH PASSWORD = 'Admin123*', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usuario_lector')   
    CREATE LOGIN usuario_lector WITH PASSWORD = 'Lector123*', CHECK_POLICY = OFF;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_admin')
    DROP USER usuario_admin;

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usuario_lector')
    DROP USER usuario_lector;
GO

CREATE USER usuario_admin FOR LOGIN usuario_admin;
CREATE USER usuario_lector FOR LOGIN usuario_lector;
GO

IF OBJECT_ID('dbo.sp_RegistrarCompraSimple', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RegistrarCompraSimple;
GO

CREATE PROCEDURE dbo.sp_RegistrarCompraSimple
    @ID_compra INT,
    @ID_empleado INT,
    @ID_metodo_pago INT,
    @ID_cliente INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente)
    VALUES (@ID_compra, @ID_empleado, @ID_metodo_pago, @ID_cliente);
END;
GO

ALTER ROLE db_owner ADD MEMBER usuario_admin;

GRANT SELECT ON dbo.PRODUCTO TO usuario_lector;
DENY INSERT, UPDATE, DELETE ON dbo.COMPRA TO usuario_lector;
GRANT EXECUTE ON dbo.sp_RegistrarCompraSimple TO usuario_lector;
GO

PRINT '=== usuario_admin y usuario_lector creados y configurados correctamente ===';

--------------------------------------------------------------------------------
-- 3. ROL PERSONALIZADO Y USUARIOS SUPERVISOR / OPERADOR
--------------------------------------------------------------------------------
-- 3. ROL PERSONALIZADO Y USUARIOS SUPERVISOR / OPERADOR

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals
    WHERE name = 'supervisor_tcg'
)
    CREATE LOGIN supervisor_tcg
    WITH PASSWORD = 'Super123*', CHECK_POLICY = OFF;

IF NOT EXISTS (
    SELECT 1 FROM sys.server_principals
    WHERE name = 'empleado_lucas'
)
    CREATE LOGIN empleado_lucas
    WITH PASSWORD = 'Lucas123*', CHECK_POLICY = OFF;
GO

IF DATABASE_PRINCIPAL_ID('rol_operador_tcg') IS NULL
    CREATE ROLE rol_operador_tcg;

IF DATABASE_PRINCIPAL_ID('supervisor_tcg') IS NULL
    CREATE USER supervisor_tcg FOR LOGIN supervisor_tcg;

IF DATABASE_PRINCIPAL_ID('empleado_lucas') IS NULL
    CREATE USER empleado_lucas FOR LOGIN empleado_lucas;
GO

GRANT SELECT ON dbo.PRODUCTO TO rol_operador_tcg;

-- Evitar agregar miembros que ya pertenecen al rol
IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members
    WHERE role_principal_id = DATABASE_PRINCIPAL_ID('rol_operador_tcg')
      AND member_principal_id = DATABASE_PRINCIPAL_ID('empleado_lucas')
)
    ALTER ROLE rol_operador_tcg ADD MEMBER empleado_lucas;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members
    WHERE role_principal_id = DATABASE_PRINCIPAL_ID('db_datareader')
        AND member_principal_id = DATABASE_PRINCIPAL_ID('supervisor_tcg')
)
    ALTER ROLE db_datareader ADD MEMBER supervisor_tcg;

IF NOT EXISTS (
    SELECT 1
    FROM sys.database_role_members
    WHERE role_principal_id = DATABASE_PRINCIPAL_ID('db_datawriter')
        AND member_principal_id = DATABASE_PRINCIPAL_ID('supervisor_tcg')
)
    ALTER ROLE db_datawriter ADD MEMBER supervisor_tcg;

GRANT EXECUTE ON dbo.sp_RegistrarCompraSimple TO supervisor_tcg;
GO
--------------------------------------------------------------------------------
-- 4. PRUEBA DE SEGURIDAD
--------------------------------------------------------------------------------
-- PRUEBA 1: usuario_lector puede LEER PRODUCTO  (ESPERADO: OK)
EXECUTE AS USER = 'usuario_lector';
SELECT USER_NAME() AS Usuario_actual;
SELECT ID_producto, Edicion, Precio_actual FROM dbo.PRODUCTO;
REVERT;
GO

-- PRUEBA 2: usuario_lector NO puede leer otra tabla  (ESPERADO: error 229, SELECT denied)
EXECUTE AS USER = 'usuario_lector';
SELECT USER_NAME() AS Usuario_actual;
SELECT * FROM dbo.CLIENTE;
REVERT;
GO

-- PRUEBA 3: usuario_lector NO puede insertar directo en COMPRA  (ESPERADO: error 229, INSERT denied)
EXECUTE AS USER = 'usuario_lector';
INSERT INTO dbo.COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente)
VALUES (900, 1, 1, 1);
REVERT;
GO

-- PRUEBA 4: usuario_lector SÍ puede registrar compra vía procedimiento  (ESPERADO: OK)
EXECUTE AS USER = 'usuario_lector';
EXEC dbo.sp_RegistrarCompraSimple @ID_compra = 901, @ID_empleado = 1,
    @ID_metodo_pago = 1, @ID_cliente = 1;
REVERT;
GO
SELECT * FROM dbo.COMPRA WHERE ID_compra = 901;   -- verificás como dbo
GO

-- PRUEBA 5: empleado_lucas (por rol) lee PRODUCTO  (ESPERADO: OK)
EXECUTE AS USER = 'empleado_lucas';
SELECT USER_NAME() AS Usuario_actual;
SELECT ID_producto, Edicion, Precio_actual, Tipo FROM dbo.PRODUCTO;
REVERT;
GO

-- PRUEBA 6: empleado_lucas NO puede insertar ni modificar  (ESPERADO: error 229)
EXECUTE AS USER = 'empleado_lucas';
INSERT INTO dbo.COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente)
VALUES (902, 1, 1, 1);
REVERT;
GO
EXECUTE AS USER = 'empleado_lucas';
UPDATE dbo.PRODUCTO SET Precio_actual = Precio_actual WHERE ID_producto = 2;
REVERT;
GO
-- PRUEBA 7: supervisor_tcg inserta directo (db_datawriter)  (ESPERADO: OK)
EXECUTE AS USER = 'supervisor_tcg';
SELECT USER_NAME() AS Usuario_actual;
INSERT INTO dbo.COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente)
VALUES (903, 1, 1, 1);
REVERT;
GO
SELECT * FROM dbo.COMPRA WHERE ID_compra = 903;
GO

-- PRUEBA 8: supervisor_tcg NO puede crear tablas  (ESPERADO: error 262, CREATE TABLE denied)
EXECUTE AS USER = 'supervisor_tcg';
CREATE TABLE dbo.TablaNoPermitida (id INT);
REVERT;
GO

-- PRUEBA 9: usuario_admin puede todo (db_owner)  (ESPERADO: OK)
EXECUTE AS USER = 'usuario_admin';
SELECT USER_NAME() AS Usuario_actual;
SELECT COUNT(*) AS Total_clientes FROM dbo.CLIENTE;
REVERT;
GO

--------------------------------------------------------------------------------
-- 5. VERIFICACION DE PERMISOS Y ROLES ASIGNADOS A CADA USUARIO
--------------------------------------------------------------------------------
SELECT 
    dp.principal_id AS ID_Usuario,
    dp.name AS Usuario_BD,
    dp.type_desc AS Tipo_Usuario,
    sp.name AS Login_Servidor,
    CASE WHEN sp.is_disabled = 0 THEN 'Activo' ELSE 'Deshabilitado' END AS Estado_Login,
    dp.create_date AS Fecha_Creacion
FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE dp.type IN ('S', 'U')
    AND dp.principal_id > 4
    AND dp.name NOT LIKE '##%'
ORDER BY dp.name;
GO

SELECT 
    u.name AS Usuario,
    r.name AS Rol_Asignado,
    CASE WHEN r.is_fixed_role = 1 THEN 'Rol Fijo del Sistema' ELSE 'Rol Personalizado' END AS Tipo_Rol
FROM sys.database_role_members drm
INNER JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
INNER JOIN sys.database_principals u ON drm.member_principal_id = u.principal_id
WHERE u.principal_id > 4
ORDER BY u.name, r.name;
GO

SELECT 
    pr.name AS Usuario_o_Rol,
    pr.type_desc AS Tipo_Principal,
    pe.state_desc AS Estado_Permiso,
    pe.permission_name AS Permiso,
    OBJECT_NAME(pe.major_id) AS Objeto_Afectado,
    o.type_desc AS Tipo_Objeto
FROM sys.database_permissions pe
INNER JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
LEFT JOIN sys.objects o ON pe.major_id = o.object_id
WHERE pr.principal_id > 4
    AND pe.major_id > 0
ORDER BY pr.name, Objeto_Afectado, pe.permission_name;
GO

SELECT USER_NAME() AS Usuario_actual;   -- debe decir 'dbo'
GO


-- Revisar el permiso del usuario que esta ejecutando esta prueba
/*SELECT
    SUSER_SNAME() AS Login_Actual,
    IS_SRVROLEMEMBER('sysadmin') AS Es_Sysadmin,
    USER_NAME() AS Usuario_BD;
GO


-- muestra la lista de usuarios antes de las pruebas
SELECT
    name AS Usuario,
    type_desc AS Tipo,
    create_date AS Fecha_Creacion
FROM sys.database_principals
WHERE name IN (
    'usuario_admin',
    'usuario_lector',
    'supervisor_tcg',
    'empleado_lucas',
    'rol_operador_tcg'
);
GO*/
