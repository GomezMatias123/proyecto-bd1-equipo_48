## 1FN: Eliminacion de grupos repetitivos y garantia de atomicidad.
Agregamos tablas multivaluadas al atributo telefono y a email cliente. Esto se cambio ya que antes los atributos email y telefono estaba en la tabla cliente, pero al ser ambos atributos multivaluados se los separo en una tabla separada para cada uno: Telefono_cliente y Email_cliente.

## 2FN: Eliminación de dependencias funcionales parciales en claves compuestas.
No hubo correcion de la 2da forma de normalizacion ya que al diseñar las tablas ya se implemento en todas una clave primaria.

## 3FN: Eliminación de dependencias transitivas en atributos no clave.
En principio la tabla Detalle_compra tenia un atributo precio_Total pero lo eliminamos ya que al incluir Cantidad y precio unitario se generaba una dependencia transitiva entre valores y no todos de la clave primaria.
