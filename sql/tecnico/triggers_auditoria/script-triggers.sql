-- ============================================================================
-- PROYECTO INTEGRADOR: DragabulK_TCG
-- ETAPA V: CREACION DE TRIGGERS
-- Alumno: Fernandez Fabio Javier (Equipo 48)
-- Base de Datos: DragabulK_TCG
-- ============================================================================


--CREACION DE TABLAS DE AUDITORIA


USE DragabulK_TCG 
GO 

CREATE TABLE AuditoriaCliente
(
  ID_cliente INT NOT NULL,
  dni VARCHAR(20) NOT NULL,
  nombreAntes VARCHAR(50) NOT NULL, --Se necesitan dos campos, uno que represente el valor antes
  nombreAhora VARCHAR(50) NOT NULL, --y el valor ahora
  apellidoAntes VARCHAR(50) NOT NULL,
  apellidoAhora VARCHAR(50) NOT NULL,
  fecha DATE NOT NULL,
  usuario VARCHAR(100) NOT NULL,
  PRIMARY KEY (ID_cliente)
);

GO

CREATE TABLE AuditoriaEmpleado
(
  ID_empleado INT NOT NULL,
  dni VARCHAR(20) NOT NULL,
  nombreAntes VARCHAR(50) NOT NULL,
  nombreAhora VARCHAR(50) NOT NULL,
  apellidoAntes VARCHAR(50) NOT NULL,
  apellidoAhora VARCHAR(50) NOT NULL,
  fecha DATE NOT NULL,
  usuario VARCHAR(100) NOT NULL,
  PRIMARY KEY (ID_empleado)
);

GO

CREATE TABLE AuditoriaProducto
(
  ID_producto INT NOT NULL,
  Edicion VARCHAR(100) NOT NULL,
  PrecioAntes INT NOT NULL,
  PrecioAhora INT NOT NULL,
  StockAntes INT NOT NULL,
  StockAhora INT NOT NULL,
  Tipo VARCHAR(50) NOT NULL,
  Fecha DATE NOT NULL,
  Usuario VARCHAR(100) NOT NULL,
  PRIMARY KEY (ID_producto)
);

GO 

CREATE TABLE AuditoriaSocio
(
  DescuentoAntes INT NOT NULL,
  DescuentoAhora INT NOT NULL,
  BeneficioAntes VARCHAR(100) NOT NULL,
  BeneficioAhora VARCHAR(100) NOT NULL,
  ID_cliente INT NOT NULL,
  Fecha DATE NOT NULL,
  Usuario VARCHAR(100) NOT NULL,
  PRIMARY KEY (ID_cliente),
  FOREIGN KEY (ID_cliente) REFERENCES CLIENTE(ID_cliente)
);

GO

CREATE TABLE AuditoriaProveedor
(
  ID_proveedor INT NOT NULL,
  nombreAntes VARCHAR(50) NOT NULL,
  nombreAhora VARCHAR(50) NOT NULL,
  tiempos_de_entregaAntes INT NOT NULL,
  tiempos_de_entregaAhora INT NOT NULL,
  ID_empleado INT NOT NULL,
  Fecha DATE NOT NULL,
  Usuario VARCHAR(100) NOT NULL,
  PRIMARY KEY (ID_proveedor),
  FOREIGN KEY (ID_empleado) REFERENCES EMPLEADO(ID_empleado)
);


-----------------------------------------------------------------------------------


--AUDITORIA DE CLIENTE 

GO

CREATE TRIGGER dbo.trg_Cliente_Auditoria
ON dbo.CLIENTE AFTER UPDATE AS
BEGIN 
    INSERT AuditoriaCliente
        (ID_cliente, dni, nombreAntes, nombreAhora,
         apellidoAntes, apellidoAhora, fecha, usuario)
    SELECT i.ID_cliente, i.dni, d.nombre , i.nombre, d.apellido, i.apellido, SYSDATETIME(), SUSER_SNAME()
    FROM inserted i JOIN deleted d 
    ON I.ID_cliente = d.ID_cliente;
END;

-----------------------------------------------------------------------------------

--AUDITORIA DE EMPLEADO

GO

CREATE TRIGGER dbo.trg_Empleado_Auditoria
ON dbo.EMPLEADO AFTER UPDATE AS
BEGIN
    INSERT dbo.AuditoriaEmpleado
        (ID_Empleado, dni, nombreAntes, nombreAhora, apellidoAntes, apellidoAhora, Fecha, Usuario)
    SELECT i.ID_empleado, i.dni, d.nombre, i.nombre, d.apellido, i.apellido, SYSDATETIME(), SUSER_SNAME()
    FROM inserted i JOIN deleted d  
    on i.ID_empleado = d.ID_empleado;
END;

-----------------------------------------------------------------------------------

--AUDITORIA DE PRODUCTO

GO  

CREATE TRIGGER dbo.trg_Producto_Auditoria
ON dbo.PRODUCTO AFTER UPDATE AS
BEGIN 
    INSERT dbo.AuditoriaProducto
        (ID_producto, Edicion, PrecioAntes, PrecioAhora, StockAntes, StockAhora, Tipo, Fecha, Usuario)
    SELECT i.ID_producto, i.Edicion, d.Precio_actual, i.Precio_actual,
           d.Stock_disponible, i.Stock_disponible, i.Tipo, SYSDATETIME(), SUSER_SNAME()
    FROM inserted i JOIN deleted d
    ON i.ID_producto = d.ID_producto;
END;

-----------------------------------------------------------------------------------

--AUDITORIA DE SOCIO

GO  

CREATE TRIGGER dbo.trg_Socio_Auditoria
ON dbo.SOCIO AFTER UPDATE AS
BEGIN 
    INSERT dbo.AuditoriaSocio
        (ID_cliente, DescuentoAntes, DescuentoAhora, BeneficioAntes, BeneficioAhora, Fecha, Usuario)
    SELECT i.ID_cliente, d.Descuento , i.Descuento, d.Beneficio, i.Beneficio, SYSDATETIME(), SUSER_SNAME()
    FROM inserted i JOIN deleted d
    ON i.ID_cliente = d.ID_cliente;
END;

-----------------------------------------------------------------------------------

----AUDITORIA DE PROVEEDOR

GO

CREATE TRIGGER dbo.trg_Proveedor_Auditoria
ON dbo.PROVEEDOR AFTER UPDATE AS
BEGIN 
    INSERT dbo.AuditoriaProveedor
        (ID_proveedor, ID_empleado, nombreAntes, nombreAhora, tiempos_de_entregaAntes, tiempos_de_entregaAhora, Fecha, Usuario)
    SELECT i.ID_proveedor, i.ID_empleado, d.nombre , i.nombre, d.tiempos_de_entrega, i.tiempos_de_entrega, SYSDATETIME(), SUSER_SNAME()
    FROM inserted i JOIN deleted d
    ON i.ID_proveedor = d.ID_proveedor AND i.ID_empleado = d.ID_empleado;
END;

-----------------------------------------------------------------------------------

--IMPIDE BORRAR TABLAS DE LA BASE DE DATOS COMO MEDIDA DE SEGURIDAD
--SE NECESITA UTILIZAR EL COMANDO: DISABLE TRIGGER dbo.impedir_borrar_tablas ON DATABASE
GO

CREATE TRIGGER impedir_borrar_tablas
ON DATABASE FOR DROP_TABLE AS
BEGIN
    RAISERROR('No se pueden borrar tablas sin autorizacion', 16, 1);
             --16 indica que el error fue por una operacion del usuario
             --1 indica en donde ocurrio el error
    ROLLBACK TRANSACTION; --CANCELA EL DROPTABLE
END;

-----------------------------------------------------------------------------------
