# SaleSight — Reporte Ejecutivo

**Cliente:** Firma de Retail Global
**Periodo analizado:** Enero 2023 – Diciembre 2024
**Preparado por:** Stiven Posada Casadiego y Josue Ribero Duarte — SaleSight Consultoria de Datos

---

## Que analizamos

Procesamos **302,010 transacciones de ventas** de una firma de retail global con presencia en 5 paises (Australia, Canada, Germany, UK y USA) y 5 categorias de producto (Books, Clothing, Electronics, Grocery y Home Decor). Los datos estaban en muy buen estado: mas del 99.85% de los registros se conservaron tras la limpieza.

---

## Seccion 1 — Adquisicion y Preparacion

El dataset fue descargado desde Kaggle usando la API oficial y cargado con `CSV.read` en Julia, que detecta automaticamente el tipo de cada columna. Encontramos que menos del **0.15%** de los registros tenia datos incompletos en columnas criticas como el monto o la fecha. Esos valores faltantes se completaron usando el valor del medio de cada categoria de producto para no distorsionar los promedios. El dataset limpio se exporto en dos formatos: `.csv` para compartir con el cliente y `.jld2` para uso interno.

**Mensaje al cliente:** Su dataset tiene 302,010 registros y 30 variables. La calidad de los datos es alta y no fue necesario eliminar registros significativos. Las decisiones de limpieza estan documentadas paso a paso en el notebook.

---

## Seccion 2 — Variables clave del negocio

Aunque el dataset registra 30 variables por transaccion, aplicamos un analisis matematico para identificar cuales son realmente importantes. El resultado: con solo **4 variables numericas** se explica el **98.7% de toda la variacion** en los datos. La variable mas determinante es el monto total de la transaccion, seguida de la cantidad de articulos y el precio unitario.

Tambien analizamos la relacion entre paises y categorias de producto. La tabla muestra que todos los mercados tienen actividad en todas las categorias, lo que indica una red comercial completamente conectada pero sin diferenciacion geografica.

**Mensaje al cliente:** No necesita monitorear 30 metricas. Con 4 indicadores bien elegidos puede controlar el 98.7% de lo que ocurre en su negocio.

---

## Seccion 3 — Hallazgos estadisticos

### Distribucion del monto por transaccion

![Distribucion del monto por transaccion](reports/images/distribucion_monto.png)

La mayoria de las transacciones se ubica entre **$200 y $2,500 USD**, con un promedio de **$1,367 USD**. El comportamiento de gasto es predecible y simetrico, lo que facilita el presupuesto y la proyeccion de ingresos.

### Gasto por segmento de cliente

![Monto por segmento de cliente](reports/images/boxplot_segmentos.png)

Los tres segmentos (New, Premium y Regular) presentan distribuciones de gasto casi identicas. La diferencia entre Premium y Regular es de apenas **$5.87 USD por transaccion** — estadisticamente insignificante (p-valor = 0.271). La segmentacion actual no capta diferencias reales de comportamiento.

**Hallazgo adicional:** La regla automatica "calificacion de 4 o mas estrellas = cliente satisfecho" predice correctamente la satisfaccion real en el **84.2% de los casos**. Esto es suficiente para un sistema de alerta temprana sin revision manual de comentarios.

---

## Seccion 4 — Red comercial y puntos de fallo

### Red comercial Pais x Categoria

![Red comercial Pais x Categoria](reports/images/red_comercial.png)

La red tiene **10 nodos** (5 paises y 5 categorias) con **25 conexiones activas**. Esta completamente interconectada: todos los mercados venden todas las categorias. Sin embargo, **Australia, Canada y Germany** concentran el mayor volumen de operaciones. Si estos tres mercados fallan simultaneamente, el **60% de las relaciones comerciales** de la red queda afectado.

---

## Que recomendamos

| Prioridad | Accion | Base del hallazgo |
|:---:|---|---|
| Alta | Redefinir la segmentacion de clientes con criterios de frecuencia de compra, valor de vida (LTV) o canal | Los 3 segmentos actuales tienen gasto identico por transaccion |
| Alta | Crear planes de contingencia para Australia, Canada y Germany | Su falla simultanea impacta el 60% de las operaciones |
| Media | Activar monitoreo automatico de satisfaccion con la regla Ratings >= 4 | Exactitud del 84.2% — viable para alertas en tiempo real |
| Media | Simplificar el sistema de reportes interno a 4 metricas clave | El 98.7% de la variacion se explica con 4 componentes |
| Baja | Explorar especializacion de oferta por pais y categoria | La red es homogenea — no hay diferenciacion geografica actualmente |

---

*Reporte generado por SaleSight — Consultoria de Datos*
*Stiven Posada Casadiego y Josue Ribero Duarte — 2025*
