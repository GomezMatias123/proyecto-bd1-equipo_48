## Documento de restricciones e integridad referencial - DragabulK TCG

El diseño físico de la base de datos para la tienda de cartas coleccionables DragabulK TCG se fundamenta en un sólido sistema de integridad referencial. Se realiza mediante uso estricto de claves foráneas que vinculan las entidades débiles o dependientes con sus respectivas entidades fuertes o padres.

## Tabla PROVEEDOR hace referencia a su tabla padre EMPLEADO 
Mediante la inclusión de la clave foránea ID_empleado. 

Esta vinculación se justifica porque todo distribuidor de cartas debe tener un empleado asignado dentro de la organización como responsable directo. De esta manera, el sistema impide registrar proveedores sin supervisión o control de un agente interno de la empresa.

## Tabla COMPRA que esta en contacto con tres entidades simultáneamente.

La tabla hace referencia a su tabla padre EMPLEADO mediante ID_empleado para identificar al cajero, a su tabla padre METODODEPAGO mediante ID_metodo_pago para validar la forma de cobro, y a su tabla padre CLIENTE mediante ID_cliente para identificar al comprador. Esta estructura garantiza la transparencia contable y la trazabilidad de cada transacción.

## La tabla DETALLE_COMPRA 

Referencia a su tabla padre COMPRA mediante ID_compra y a su tabla padre PRODUCTO mediante ID_producto. Al conformar una clave primaria compuesta, esta relación asegura que no existan líneas de facturación aisladas y que cada unidad vendida corresponda estrictamente a un pedido vigente y a un producto real del catálogo.

## La tabla SOCIO 

Hace referencia a su tabla padre CLIENTE a través de ID_cliente, campo que actúa como clave primaria y foránea a la vez. Este diseño de especialización uno a uno se justifica porque un socio es una extensión de un comprador común. La restricción asegura que los descuentos y beneficios exclusivos solo se otorguen a personas previamente registradas en el registro general de clientes.

## La tabla REPOSICION_PRODUCTOS

Esta relacionada con su tabla padre PROVEEDOR mediante ID_proveedor y a su tabla padre PRODUCTO mediante ID_producto. Esta restricción es crítica para el almacén, ya que impide el ingreso irregular de mercancía o el registro de stock proveniente de distribuidores inexistentes, validando que cada lote esté respaldado de forma real.

## Las tablas telefono y email

Las tablas PROVEEDOR_TELEFONO y PROVEEDOR_EMAIL hacen referencia a PROVEEDOR; la tabla telefono_empleado hace referencia a EMPLEADO; y las tablas Telefono_cliente y Email_cliente hacen referencia a CLIENTE. Todas utilizan sus respectivas claves foráneas para evitar la duplicación en las tablas principales y asegurar que, ante cualquier baja, no queden datos de contacto residuales o desvinculados en el sistema.