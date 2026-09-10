# Decisiones de diseño

## Socio como subtipo de Cliente
Se modela Socio como especialización de Cliente (relación 1 a 1 mediante DNI como FK) en
lugar de una entidad independiente con atributos duplicados. Esto evita redundancia e
inconsistencias en los datos personales compartidos (RN.02).

## Entidad asociativa Detalle_Compra
La relación N:M entre Compra y Producto se resuelve mediante una entidad asociativa que
almacena cantidad y precio unitario por línea, en lugar de guardar esos datos directamente
en Compra. Esto permite que una compra contenga múltiples productos distintos (RN.04) y
preserva el historial de precios sin afectar retroactivamente ventas anteriores (RN.07).
