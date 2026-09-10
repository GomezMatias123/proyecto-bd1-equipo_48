# Reglas de Negocio (RN)

| Código | Regla |
|--------|-------|
- RN.01: Un empleado puede contactar a varios proveedores, pero un proveedor solo puede
estar en contacto con un único empleado.
- RN.02: Se debe permitir que una misma persona posea simultáneamente el rol de cliente y el
de socio, sin duplicar datos personales.
- RN.03: Un empleado puede gestionar varias compras, pero una compra solo puede ser
gestionada por un único empleado.
- RN.04: Un producto puede estar en varias compras y una compra puede tener varios
productos similares o diferentes.
- RN.05: El stock de un producto se reduce automáticamente al confirmarse una compra y
debe ser mayor a cero para permitir la venta.
- RN.06: Todo cliente debe registrarse con DNI único antes de poder realizar una compra.
- RN.07: El precio unitario de un producto en el detalle de una compra queda fijo al momento
de la transacción y no se modifica, aunque cambie el precio vigente del producto.
- RN.08: Toda compra debe especificar un único método de pago.
- RN.09: Un socio accede a beneficios y porcentajes de descuentos aplicados a sus compras,
esos valores se registran en el perfil del socio que queda registrado en el sistema, un cliente
sin estado de socio no accede a esos valores.