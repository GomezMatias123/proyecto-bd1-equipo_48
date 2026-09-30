# IMPLEMENTACION DE LA BASE DE DATOS. EXPLICACIÓN

Se crea la base de datos Drabulk_TCG. Luego nos colocamos dentro de esta y empezamos a trabajar. 

## Se crean primero las tablas fuertes que no dependen de ninguna otra tabla:
 Cliente, Empleado, Producto, MetododePago, . 

## Luego se añaden las tablas debiles que dependeran de otras tablas:
 Proveedor, Compra, Detalle_Compra, Socio, Reposicion_Productos, Proveedor_Telefono, Proveedor_Email, Telefono_Empleado, Telefono_cliente, Email_cliente.

### Cliente:
la columna ID_cliente(int) como clave primaria. Tambien se añaden las columnas dni(varchar), nombre (varchar), apellido (varchar). 

### Empleado: 
tiene la columna ID_empleado(int) como clave primaria. Tambien se añaden las columnas dni(varchar),apellido(varchar), nombre (varchar).

### Proveedor:
tiene la columna ID_proveedor(int) como clave primaria. Tambien se añaden las columnas nombre(varchar), tiempos_de_entrega(int). Se añade ID_empleado(int) como clave foranea.

### Producto:
tiene la columna ID_producto(int) como clave primaria. Tambien se añaden las columnas Edicion(varchar), Precio_actual(int), Stock_disponible(int), Tipo(varchar).

### MetododePago: 
tiene la columna ID_metodo_pago(int) como clave primaria. Tambien se añaden la columna nombre(varchar).

### Compra:
tiene la columna ID_compra(int) como clave primaria. Se añaden las columnas ID_empleado(int), ID_metodo_pago(int), ID_cliente(int) como claves foraneas.  

### Detalle_compra: 
tiene las columnas ID_compra y ID_producto como clave primaria compuesta. Las columnas ID_compra(int) e ID_producto(int) como claves foraneas. 

### Socio:
tiene la columna ID_cliente como clave primaria. Se añade la columna Beneficio(varchar). La columna ID_cliente(int) como clave foranea. 

### Reposicion_Productos: 
tiene la columna ID_reposicion como clave primaria. Se añaden tambien las columnas Fecha(date), Cantidad(int). Tiene las columnas ID_proveedor(int) e ID_producto(int) como claves foraneas. 

### Proveedor_telefono:
tiene la columna Email(varchar) como clave primaria. La columna ID_proveedor(int) como clave foranea.

### telefono_empleado:
tiene la columna Telefono(varchar) como clave primaria. La columna ID_empleado(int) como clave foranea. 

### telefono_cliente: 
tiene la columna Telefono(varchar) como clave primari. La columan ID_cliente(int) como clave foranea.

### Email_cliente: 
tiene la columan email(varchar) como clave primaria. La columan ID_cliente(int) como clave foranea.
