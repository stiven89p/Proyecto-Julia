module Graficos

# Módulo de visualización (equivalente a plots.py)
# Se llama Graficos para no colisionar con el paquete Plots.jl

import Plots as Plt
using StatsPlots
using DataFrames, Dates, Statistics, Logging
using ..Config: RUTA_GRAFICOS, NOMBRE_DB
using ..Dataset: obtener_datos_db

# Formatea un número como cadena de dinero
function _formato_moneda(x::Number)::String
    x >= 1_000_000 && return "\$$(round(x / 1e6, digits=1))M"
    return "\$$(round(Int, x))"
end

function ejecutar_graficacion(df::DataFrame)
    mkpath(RUTA_GRAFICOS)
    @info "Generando visualizaciones en: $RUTA_GRAFICOS..."

    Plt.gr()  # backend GR, equivalente a matplotlib
    Plt.default(size=(800, 500), margin=5Plt.mm)

    # 1. Ventas totales por categoría
    col_cat = "Product" in names(df) ? "Product" : "Product_Category"
    if col_cat in names(df) && "Total_Amount" in names(df)
        ventas_cat = combine(groupby(df, col_cat), :Total_Amount => sum => :Total)
        sort!(ventas_cat, :Total)
        p = Plt.bar(
            ventas_cat[!, col_cat], ventas_cat.Total;
            orientation=:h,
            title="Ingresos Totales por $col_cat",
            xlabel="Ventas (\$)", ylabel=col_cat,
            color=:steelblue, legend=false
        )
        Plt.savefig(p, joinpath(RUTA_GRAFICOS, "ventas_por_categoria.png"))
        @info "Guardado: ventas_por_categoria.png"
    end

    # 2. Perfil del cliente: nivel de ingreso y género
    if "Income" in names(df) && "Gender" in names(df)
        df_temp = dropmissing(df[!, ["Income", "Gender"]])
        p = @df df_temp StatsPlots.groupedbar(
            :Income;
            group=:Gender,
            title="Perfil del Cliente: Nivel de Ingreso y Género",
            xlabel="Nivel de Ingreso", ylabel="Cantidad de Clientes",
            palette=:muted
        )
        Plt.savefig(p, joinpath(RUTA_GRAFICOS, "perfil_cliente_ingresos.png"))
        @info "Guardado: perfil_cliente_ingresos.png"
    end

    # 3. Distribución de métodos de pago (gráfico de torta)
    if "Payment_Method" in names(df)
        pagos = combine(groupby(dropmissing(df[!, ["Payment_Method"]]), :Payment_Method), nrow => :n)
        p = Plt.pie(
            pagos.Payment_Method, pagos.n;
            title="Distribución de Métodos de Pago"
        )
        Plt.savefig(p, joinpath(RUTA_GRAFICOS, "preferencia_metodos_pago.png"))
        @info "Guardado: preferencia_metodos_pago.png"
    end

    # 4. Tendencia de ventas mensuales
    if "Date" in names(df) && "Total_Amount" in names(df)
        df_temp = copy(df[!, ["Date", "Total_Amount"]])
        dropmissing!(df_temp)
        df_temp.Mes = Dates.month.(df_temp.Date)
        tendencia = combine(groupby(df_temp, :Mes), :Total_Amount => sum => :Total)
        sort!(tendencia, :Mes)

        nombres_meses = ["Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic"]
        etiquetas = nombres_meses[tendencia.Mes]

        p = Plt.plot(
            etiquetas, tendencia.Total;
            marker=:circle, color=:forestgreen, linewidth=2,
            title="Tendencia Histórica de Ventas Mensuales",
            xlabel="Mes", ylabel="Ventas Totales (\$)",
            legend=false, grid=true
        )
        Plt.savefig(p, joinpath(RUTA_GRAFICOS, "tendencia_mensual_ventas.png"))
        @info "Guardado: tendencia_mensual_ventas.png"
    end

    # 5. Top 5 países por ventas
    if "Country" in names(df) && "Total_Amount" in names(df)
        paises = combine(groupby(dropmissing(df[!, ["Country", "Total_Amount"]]), :Country),
                         :Total_Amount => sum => :Total)
        sort!(paises, :Total, rev=true)
        top5 = first(paises, 5)
        sort!(top5, :Total)

        p = Plt.bar(
            top5.Country, top5.Total;
            orientation=:h,
            title="Top 5 Países con Mayor Facturación",
            xlabel="Ventas Totales (\$)", ylabel="País",
            color=:salmon, legend=false
        )
        Plt.savefig(p, joinpath(RUTA_GRAFICOS, "top_paises_ventas.png"))
        @info "Guardado: top_paises_ventas.png"
    end

    @info "¡Éxito! Gráficos generados correctamente en $RUTA_GRAFICOS."
end

function generar_reporte_visual(nombre_bd::String = NOMBRE_DB)
    df = obtener_datos_db(nombre_bd)
    if !isnothing(df)
        ejecutar_graficacion(df)
    else
        @error "No hay datos para graficar."
    end
end

end
