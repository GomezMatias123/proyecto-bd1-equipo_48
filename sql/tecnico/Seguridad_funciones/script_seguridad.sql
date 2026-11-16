-- Active: 1731791657098@@127.0.0.1@5432@e-commerce
USE DragabulK_TCG;
GO

PRINT '=== 01. VERIFICACION DE DATOS CARGADOS ===';
SELECT * FROM PRODUCTO;
SELECT * FROM CLIENTE;
SELECT * FROM EMPLEADO;
SELECT * FROM METODO_PAGO;
SELECT * FROM COMPRA;

GO

PRINT '=== 02. MATRIZ DE USUARIOS, ROLES Y PERMISOS ===';
SELECT 
    p.name AS Usuario,
    p.type_desc AS Tipo_Usuario,
    ISNULL(r.name, 'Sin Rol Asignado (Permisos Directos)') AS Rol_Asociado,
    ISNULL(perm.permission_name, 'Sin Permisos Específicos') AS Permiso,
    ISNULL(perm.state_desc, 'N/A') AS Estado,
    ISNULL(OBJECT_NAME(perm.major_id), 'Base de Datos Completa') AS Objeto_Afectado
FROM sys.database_principals p
LEFT JOIN sys.database_role_members rm ON p.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
LEFT JOIN sys.database_permissions perm ON perm.grantee_principal_id = p.principal_id 
    OR perm.grantee_principal_id = r.principal_id
WHERE p.type IN ('S', 'U')
ORDER BY p.name, Rol_Asociado;

PRINT '=== 03. PRUEBA DE INSERCION DIRECTA COMO LECTOR (ESPERADO: ERROR 229) ===';
EXECUTE AS USER = 'usuario_lector';
GO

INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente) 
VALUES (20, 1, 1, 1);
GO

REVERT;
GO

PRINT '=== 04. PRUEBA DE PROCEDIMIENTO ALMACENADO COMO LECTOR (ESPERADO: EXITO) ===';
EXECUTE AS USER = 'usuario_lector';
GO

EXEC dbo.sp_RegistrarCompraSimple 
    @ID_compra = 20, 
    @ID_empleado = 1, 
    @ID_metodo_pago = 1, 
    @ID_cliente = 1;
GO

REVERT;
GO

-- Verificamos que el registro 20 ingresó correctamente
SELECT * FROM COMPRA WHERE ID_compra = 20;
GO

PRINT '=== 05. FALLO DE INSERCION DIRECTA POR EMPLEADO (ESPERADO: ERROR 229) ===';
EXECUTE AS USER = 'empleado_lucas';
GO

INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente) 
VALUES (21, 1, 1, 1);
GO

REVERT;
GO

PRINT '=== 06. INSERCION VALIDA COMO SUPERVISOR (ESPERADO: EXITO) ===';
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


PRINT '=== 07. DISTINCION DE ACCION POR TIPO DE USUARIO Y ROLES ===';
SELECT 
    p.name AS Usuario,
    p.type_desc AS Tipo_Usuario,
    ISNULL(r.name, 'Sin Rol Asignado (Permisos Directos)') AS Rol_Asociado,
    ISNULL(perm.permission_name, 'Sin Permisos Específicos') AS Permiso,
    ISNULL(perm.state_desc, 'N/A') AS Estado,
    ISNULL(OBJECT_NAME(perm.major_id), 'Base de Datos Completa') AS Objeto_Afectado
FROM sys.database_principals p
LEFT JOIN sys.database_role_members rm ON p.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
LEFT JOIN sys.database_permissions perm ON perm.grantee_principal_id = p.principal_id 
    OR perm.grantee_principal_id = r.principal_id
WHERE p.type IN ('S', 'U')
    AND p.name IN ('usuario_admin', 'supervisor_tcg', 'usuario_lector', 'empleado_lucas')
ORDER BY p.name, Rol_Asociado, Permiso;
GO