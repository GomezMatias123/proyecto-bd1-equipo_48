USE DragabulK_TCG;
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

SELECT @sql += N'SELECT ''' + t.name + N''' AS Tabla, * FROM ' 
            + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name) + N';' + CHAR(13)
FROM sys.tables t
ORDER BY t.name;

EXEC sp_executesql @sql;
GO

--------------------------------------------------------------------------------
-- 2. ASIGNACION DE ROLES DE ADMIN Y LECTOR
--------------------------------------------------------------------------------

CREATE LOGIN usuario_admin WITH PASSWORD = 'Admin123*', CHECK_POLICY = OFF;
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

EXEC sp_addrolemember 'db_owner', 'usuario_admin';

GRANT SELECT ON dbo.PRODUCTO TO usuario_lector;
DENY INSERT, UPDATE, DELETE ON dbo.COMPRA TO usuario_lector;
GRANT EXECUTE ON dbo.sp_RegistrarCompraSimple TO usuario_lector;
GO

PRINT '=== usuario_admin y usuario_lector creados y configurados correctamente ===';

--------------------------------------------------------------------------------
-- 3. PRUEBA DE INSERCION DIRECTA CON LECTOR
--------------------------------------------------------------------------------
EXECUTE AS USER = 'usuario_lector';
GO

INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente) 
VALUES (20, 1, 1, 1);
GO


--------------------------------------------------------------------------------
-- 4. PRUEBA DE PROCEDIMIENTO ALMACENADO CON LECTOR
--------------------------------------------------------------------------------
EXECUTE AS USER = 'usuario_lector';
GO

EXEC dbo.sp_RegistrarCompraSimple 
    @ID_compra = 20, 
    @ID_empleado = 1, 
    @ID_metodo_pago = 1, 
    @ID_cliente = 1;
GO


-- Verificamos que el registro 20 ingresó correctamente
SELECT * FROM COMPRA WHERE ID_compra = 20;
GO

--------------------------------------------------------------------------------
-- . ASIGNACION DE ROLES DE ADMIN Y LECTOR
--------------------------------------------------------------------------------
CREATE ROLE rol_operador_tcg;
GO

GRANT SELECT ON dbo.PRODUCTO TO rol_operador_tcg;
GO

USE master;
GO
CREATE LOGIN supervisor_tcg WITH PASSWORD = 'Super123*', CHECK_POLICY = OFF;
CREATE LOGIN empleado_lucas WITH PASSWORD = 'Lucas123*', CHECK_POLICY = OFF;
GO

USE DragabulK_TCG;
GO

CREATE USER supervisor_tcg FOR LOGIN supervisor_tcg;
CREATE USER empleado_lucas FOR LOGIN empleado_lucas;
GO

ALTER ROLE rol_operador_tcg ADD MEMBER empleado_lucas;
GO

EXEC sp_addrolemember 'db_datareader', 'supervisor_tcg';
EXEC sp_addrolemember 'db_datawriter', 'supervisor_tcg';
GRANT EXECUTE ON dbo.sp_RegistrarCompraSimple TO supervisor_tcg;

GRANT SELECT ON dbo.PRODUCTO TO rol_operador_tcg;
EXEC sp_addrolemember 'rol_operador_tcg', 'empleado_lucas';
GO

EXECUTE AS USER = 'empleado_lucas';
GO

SELECT ID_producto, Edicion, Precio_actual, Tipo FROM PRODUCTO

INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente)
VALUES (11, 1, 1, 1);
GO

--------------------------------------------------------------------------------
-- 6. VALIDES PARA EL USUARIO SUPERVISOR
--------------------------------------------------------------------------------
EXECUTE AS USER = 'supervisor_tcg';
GO

-- Inserción directa permitida por rol db_datawriter
INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente) 
VALUES (21, 1, 1, 1);
GO

REVERT;
GO

-- Verificamos que el registro 21 se guardó correctamente
SELECT * FROM COMPRA WHERE ID_compra = 21;
GO


--------------------------------------------------------------------------------
-- 7. VERIFICACION DE PERMISOS Y ROLES ASIGNADOS A CADA USUARIO
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