CREATE DATABASE DragabulK_TCG;
GO

USE DragabulK_TCG;
GO

CREATE TABLE CLIENTE
(
  ID_cliente INT NOT NULL,
  dni VARCHAR(20) NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  apellido VARCHAR(50) NOT NULL,
  PRIMARY KEY (ID_cliente)
);

CREATE TABLE EMPLEADO
(
  ID_empleado INT NOT NULL,
  apellido VARCHAR(50) NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  dni VARCHAR(20) NOT NULL,
  PRIMARY KEY (ID_empleado)
);

CREATE TABLE PROVEEDOR
(
  ID_proveedor INT NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  tiempos_de_entrega INT NOT NULL,
  ID_empleado INT NOT NULL,
  PRIMARY KEY (ID_proveedor),
  FOREIGN KEY (ID_empleado) REFERENCES EMPLEADO(ID_empleado)
);

CREATE TABLE PRODUCTO
(
  ID_producto INT NOT NULL,
  Edicion VARCHAR(100) NOT NULL,
  Precio_actual INT NOT NULL,
  Stock_disponible INT NOT NULL,
  Tipo VARCHAR(50) NOT NULL,
  PRIMARY KEY (ID_producto)
);

CREATE TABLE METODODEPAGO
(
  ID_metodo_pago INT NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  PRIMARY KEY (ID_metodo_pago)
);

CREATE TABLE COMPRA
(
  ID_compra INT NOT NULL,
  ID_empleado INT NOT NULL,
  ID_metodo_pago INT NOT NULL,
  ID_cliente INT NOT NULL,
  PRIMARY KEY (ID_compra),
  FOREIGN KEY (ID_empleado) REFERENCES EMPLEADO(ID_empleado),
  FOREIGN KEY (ID_metodo_pago) REFERENCES METODODEPAGO(ID_metodo_pago),
  FOREIGN KEY (ID_cliente) REFERENCES CLIENTE(ID_cliente)
);

CREATE TABLE DETALLE_COMPRA
(
  Precio_unitario INT NOT NULL,
  Cantidad INT NOT NULL,
  ID_compra INT NOT NULL,
  ID_producto INT NOT NULL,
  PRIMARY KEY (ID_compra, ID_producto),
  FOREIGN KEY (ID_compra) REFERENCES COMPRA(ID_compra),
  FOREIGN KEY (ID_producto) REFERENCES PRODUCTO(ID_producto)
);

CREATE TABLE SOCIO
(
  Descuento INT NOT NULL,
  Beneficio VARCHAR(100) NOT NULL,
  ID_cliente INT NOT NULL,
  PRIMARY KEY (ID_cliente),
  FOREIGN KEY (ID_cliente) REFERENCES CLIENTE(ID_cliente)
);

CREATE TABLE REPOSICION_PRODUCTOS
(
  Fecha DATE NOT NULL,
  Cantidad INT NOT NULL,
  ID_reposicion INT NOT NULL,
  ID_proveedor INT NOT NULL,
  ID_producto INT NOT NULL,
  PRIMARY KEY (ID_reposicion),
  FOREIGN KEY (ID_proveedor) REFERENCES PROVEEDOR(ID_proveedor),
  FOREIGN KEY (ID_producto) REFERENCES PRODUCTO(ID_producto)
);

CREATE TABLE PROVEEDOR_TELEFONO
(
  Telefono VARCHAR(50) NOT NULL,
  ID_proveedor INT NOT NULL,
  PRIMARY KEY (Telefono),
  FOREIGN KEY (ID_proveedor) REFERENCES PROVEEDOR(ID_proveedor)
);

CREATE TABLE PROVEEDOR_EMAIL
(
  Email VARCHAR(50) NOT NULL,
  ID_proveedor INT NOT NULL,
  PRIMARY KEY (Email),
  FOREIGN KEY (ID_proveedor) REFERENCES PROVEEDOR(ID_proveedor)
);

CREATE TABLE telefono_empleado
(
  telefono VARCHAR(50) NOT NULL,
  ID_empleado INT NOT NULL,
  PRIMARY KEY (telefono),
  FOREIGN KEY (ID_empleado) REFERENCES EMPLEADO(ID_empleado)
);

CREATE TABLE Telefono_cliente
(
  Telefono VARCHAR(50) NOT NULL,
  ID_cliente INT NOT NULL,
  PRIMARY KEY (Telefono),
  FOREIGN KEY (ID_cliente) REFERENCES CLIENTE(ID_cliente)
);

CREATE TABLE Email_cliente
(
  email VARCHAR(100) NOT NULL,
  ID_cliente INT NOT NULL,
  PRIMARY KEY (email),
  FOREIGN KEY (ID_cliente) REFERENCES CLIENTE(ID_cliente)
);
