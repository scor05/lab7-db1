-- Tab 1: Desempeño de Ventas

-- KPI 1: Ingresos netos por mes
SELECT
    DATE_TRUNC('month', p.fecha) AS mes,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_netos
FROM pedido p
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.estado = 'completado'
GROUP BY 1
ORDER BY 1;

-- KPI 2: Ingresos por tienda
SELECT
    t.nombre AS tienda,
    t.region,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_netos,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos
FROM tienda t
JOIN pedido p ON p.id_tienda = t.id_tienda
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.estado = 'completado'
GROUP BY t.id_tienda, t.nombre, t.region
ORDER BY ingresos_netos DESC;

-- KPI 3: Ingresos por canal
SELECT
    p.canal,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_netos
FROM pedido p
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.estado = 'completado'
GROUP BY p.canal;

-- KPI 4: Ticket promedio por pedido
SELECT
    ROUND(
        SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0))
        / COUNT(DISTINCT p.id_pedido),
    2) AS ticket_promedio_Q
FROM pedido p
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.estado = 'completado';

-- KPI 5: Tasa de cancelación y devolución por mes
SELECT
    DATE_TRUNC('month', fecha) AS mes,
    estado,
    COUNT(*) AS cantidad_pedidos,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY DATE_TRUNC('month', fecha)), 2) AS pct_del_mes
FROM pedido
GROUP BY 1, 2
ORDER BY 1, 2;

-- KPI 6: Top 10 empleados por ventas generadas
SELECT
    e.nombre AS empleado,
    e.puesto,
    t.nombre AS tienda,
    COUNT(DISTINCT p.id_pedido) AS pedidos_cerrados,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_generados
FROM empleado e
JOIN pedido p ON p.id_empleado = e.id_empleado
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
JOIN tienda t ON t.id_tienda = e.id_tienda
WHERE p.estado = 'completado'
GROUP BY e.id_empleado, e.nombre, e.puesto, t.nombre
ORDER BY ingresos_generados DESC
LIMIT 10;

-- Tab 2: Análisis de Productos y Clientes

-- KPI 7: Top 10 productos más vendidos
SELECT
    pr.nombre AS producto,
    cat.nombre AS categoria,
    SUM(dp.cantidad) AS unidades_vendidas,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_netos
FROM detalle_pedido dp
JOIN pedido p ON p.id_pedido = dp.id_pedido
JOIN producto pr ON pr.id_producto = dp.id_producto
JOIN categoria cat ON cat.id_categoria = pr.id_categoria
WHERE p.estado = 'completado'
GROUP BY pr.id_producto, pr.nombre, cat.nombre
ORDER BY unidades_vendidas DESC
LIMIT 10;

-- KPI 8: Ingresos por categoría
SELECT
    cat.departamento,
    cat.nombre AS categoria,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_netos,
    SUM(dp.cantidad) AS unidades_vendidas
FROM detalle_pedido dp
JOIN pedido p ON p.id_pedido = dp.id_pedido
JOIN producto pr ON pr.id_producto = dp.id_producto
JOIN categoria cat ON cat.id_categoria = pr.id_categoria
WHERE p.estado = 'completado'
GROUP BY cat.departamento, cat.nombre
ORDER BY ingresos_netos DESC;

-- KPI 9: Margen bruto por categoría
SELECT
    cat.nombre AS categoria,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_netos,
    ROUND(SUM(dp.cantidad * pr.precio_costo), 2) AS costo_total,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0))
          - SUM(dp.cantidad * pr.precio_costo), 2) AS margen_bruto,
    ROUND(100.0 *
        (SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0))
         - SUM(dp.cantidad * pr.precio_costo))
        / SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS margen_pct
FROM detalle_pedido dp
JOIN pedido p ON p.id_pedido = dp.id_pedido
JOIN producto pr ON pr.id_producto = dp.id_producto
JOIN categoria cat ON cat.id_categoria = pr.id_categoria
WHERE p.estado = 'completado'
GROUP BY cat.nombre
ORDER BY margen_bruto DESC;

-- KPI 10: Ventas por segmento de cliente
SELECT
    c.segmento,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    COUNT(DISTINCT p.id_cliente) AS clientes_activos,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_netos,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0))
          / COUNT(DISTINCT p.id_pedido), 2) AS ticket_promedio
FROM cliente c
JOIN pedido p ON p.id_cliente = c.id_cliente
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.estado = 'completado'
GROUP BY c.segmento
ORDER BY ingresos_netos DESC;

-- KPI 11: Descuento promedio por categoría
SELECT
    cat.nombre AS categoria,
    ROUND(AVG(dp.descuento), 2) AS descuento_promedio_pct,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (dp.descuento / 100.0)), 2) AS monto_total_descontado
FROM detalle_pedido dp
JOIN pedido p ON p.id_pedido = dp.id_pedido
JOIN producto pr ON pr.id_producto = dp.id_producto
JOIN categoria cat ON cat.id_categoria = pr.id_categoria
WHERE p.estado = 'completado'
  AND dp.descuento > 0
GROUP BY cat.nombre
ORDER BY descuento_promedio_pct DESC;

-- KPI 12: Top 10 clientes por valor acumulado
SELECT
    c.nombre AS cliente,
    c.segmento,
    c.ciudad,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS valor_total_Q
FROM cliente c
JOIN pedido p ON p.id_cliente = c.id_cliente
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE p.estado = 'completado'
GROUP BY c.id_cliente, c.nombre, c.segmento, c.ciudad
ORDER BY valor_total_Q DESC
LIMIT 10;