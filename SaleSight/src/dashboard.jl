module Dashboard

# Dashboard interactivo (equivalente a dashboard.py con Streamlit)
# Usa Dash.jl + PlotlyJS.jl como reemplazo de Streamlit + Plotly

using Dash
using PlotlyJS
using CSV, DataFrames, Dates, Statistics, Logging
using ..Config: DATOS_PROCESADOS

# ─── Carga de datos ────────────────────────────────────────────────────────────

function cargar_datos()::DataFrame
    ruta_csv = joinpath(DATOS_PROCESADOS, "processed_data.csv")
    df = CSV.read(ruta_csv, DataFrame)

    if "Date" in names(df)
        df[!, :Date] = Dates.Date.(string.(df[!, :Date]))
    elseif "Order Date" in names(df)
        df[!, Symbol("Order Date")] = Dates.Date.(string.(df[!, Symbol("Order Date")]))
        df[!, :Date] = df[!, Symbol("Order Date")]
    end

    dropmissing!(df, :Date)
    df[!, :Month_Year] = Dates.format.(df.Date, "yyyy-mm")

    cols_str = ["products","Product_Category","Product_Brand","Gender",
                "Payment_Method","Country","Customer_Segment"]
    for col in cols_str
        col in names(df) && (df[!, col] = string.(df[!, col]))
    end

    return df
end

# ─── Helpers de PlotlyJS ───────────────────────────────────────────────────────

function _fig_linea(df::DataFrame, x::Symbol, y::Symbol; titulo="", xlabel="", ylabel="")
    trace = PlotlyJS.scatter(x=df[!, x], y=df[!, y], mode="lines+markers",
                             line_shape="spline", marker_size=6,
                             line_color="#1f77b4")
    layout = PlotlyJS.Layout(title=titulo, xaxis_title=xlabel, yaxis_title=ylabel)
    PlotlyJS.plot(trace, layout)
end

function _fig_torta(labels, values; titulo="")
    trace  = PlotlyJS.pie(labels=labels, values=values)
    layout = PlotlyJS.Layout(title=titulo)
    PlotlyJS.plot(trace, layout)
end

function _fig_barras_h(categorias, valores; titulo="", xlabel="", ylabel="", color="#1f77b4")
    trace  = PlotlyJS.bar(x=valores, y=categorias, orientation="h",
                          marker_color=color)
    layout = PlotlyJS.Layout(title=titulo, xaxis_title=xlabel, yaxis_title=ylabel)
    PlotlyJS.plot(trace, layout)
end

function _fig_barras_agrupadas(df::DataFrame, x::Symbol, y::Symbol, group::Symbol; titulo="")
    grupos  = unique(df[!, group])
    trazas  = [PlotlyJS.bar(
                   name=string(g),
                   x=df[df[!, group] .== g, x],
                   y=df[df[!, group] .== g, y]
               ) for g in grupos]
    layout  = PlotlyJS.Layout(title=titulo, barmode="group")
    PlotlyJS.plot(trazas, layout)
end

function _fig_dispersion(df::DataFrame, x::Symbol, y::Symbol, color::Symbol; titulo="")
    grupos = unique(df[!, color])
    trazas = [PlotlyJS.scatter(
                  name=string(g),
                  x=df[df[!, color] .== g, x],
                  y=df[df[!, color] .== g, y],
                  mode="markers", opacity=0.6
              ) for g in grupos]
    layout = PlotlyJS.Layout(title=titulo)
    PlotlyJS.plot(trazas, layout)
end

function _fig_histograma(df::DataFrame, col::Symbol; titulo="", nbins=20)
    trace  = PlotlyJS.histogram(x=df[!, col], nbinsx=nbins, marker_color="#2ecc71")
    layout = PlotlyJS.Layout(title=titulo)
    PlotlyJS.plot(trace, layout)
end

function _fig_mapa(df::DataFrame; titulo="")
    trace  = PlotlyJS.choropleth(locations=df.Country,
                                 locationmode="country names",
                                 z=df.Total_Amount,
                                 colorscale="Blues")
    layout = PlotlyJS.Layout(title=titulo, height=550)
    PlotlyJS.plot(trace, layout)
end

# ─── Aplicación Dash ───────────────────────────────────────────────────────────

function iniciar_dashboard(host="0.0.0.0", port=8050)
    df_global = cargar_datos()

    paises_opts    = [Dict("label" => p, "value" => p)
                      for p in sort(unique(df_global.Country))]
    segmentos_opts = [Dict("label" => s, "value" => s)
                      for s in sort(unique(df_global.Customer_Segment))]
    cats_opts      = [Dict("label" => c, "value" => c)
                      for c in sort(unique(df_global.Product_Category))]
    pagos_opts     = [Dict("label" => m, "value" => m)
                      for m in sort(unique(df_global.Payment_Method))]

    fecha_min = string(minimum(df_global.Date))
    fecha_max = string(maximum(df_global.Date))

    app = dash(assets_folder=joinpath(dirname(@__DIR__), "assets"))

    app.layout = html_div(style=Dict("fontFamily" => "Arial, sans-serif",
                                     "backgroundColor" => "#f5f7f9")) do

        # Título
        html_div(style=Dict("padding" => "20px 30px",
                            "backgroundColor" => "#1f77b4",
                            "color" => "white")) do
            html_h1("📊 SaleSight: Análisis de Ventas Retail",
                    style=Dict("margin" => "0")),
            html_p("Dashboard interactivo para el monitoreo de KPIs y tendencias comerciales globales.",
                   style=Dict("margin" => "5px 0 0 0"))
        end,

        html_div(style=Dict("display" => "flex")) do

            # Sidebar de filtros
            html_div(style=Dict("width" => "280px", "minWidth" => "280px",
                                "padding" => "20px",
                                "backgroundColor" => "#ffffff",
                                "borderRight" => "1px solid #dee2e6")) do
                html_h3("Panel de Filtros"),

                html_label("Países"),
                dcc_dropdown(id="filtro-paises",
                    options=paises_opts,
                    value=[p["value"] for p in paises_opts[1:min(5, end)]],
                    multi=true),

                html_label("Segmento de Cliente", style=Dict("marginTop" => "15px")),
                dcc_dropdown(id="filtro-segmentos",
                    options=segmentos_opts,
                    value=[s["value"] for s in segmentos_opts],
                    multi=true),

                html_label("Categorías de Producto", style=Dict("marginTop" => "15px")),
                dcc_dropdown(id="filtro-categorias",
                    options=cats_opts,
                    value=[c["value"] for c in cats_opts],
                    multi=true),

                html_label("Métodos de Pago", style=Dict("marginTop" => "15px")),
                dcc_dropdown(id="filtro-pagos",
                    options=pagos_opts,
                    value=[p["value"] for p in pagos_opts],
                    multi=true),

                html_label("Rango de Fechas", style=Dict("marginTop" => "15px")),
                dcc_datepickerrange(
                    id="filtro-fechas",
                    min_date_allowed=fecha_min,
                    max_date_allowed=fecha_max,
                    start_date=fecha_min,
                    end_date=fecha_max,
                    display_format="YYYY-MM-DD"
                )
            end,

            # Contenido principal con pestañas
            html_div(style=Dict("flex" => "1", "padding" => "20px")) do

                # KPIs
                html_div(id="kpis",
                         style=Dict("display" => "flex", "gap" => "15px",
                                    "marginBottom" => "20px")),

                # Pestañas
                dcc_tabs(id="tabs", value="tab-resumen") do
                    dcc_tab(label="📈 Resumen Ejecutivo", value="tab-resumen"),
                    dcc_tab(label="📦 Análisis de Productos", value="tab-productos"),
                    dcc_tab(label="👥 Perfil del Cliente", value="tab-clientes"),
                    dcc_tab(label="🌍 Análisis Geográfico", value="tab-geografia")
                end,

                html_div(id="contenido-tab")
            end
        end
    end

    # ─── Callback principal ─────────────────────────────────────────────────────
    callback!(app,
        Output("kpis",          "children"),
        Output("contenido-tab", "children"),
        Input("tabs",            "value"),
        Input("filtro-paises",   "value"),
        Input("filtro-segmentos","value"),
        Input("filtro-categorias","value"),
        Input("filtro-pagos",    "value"),
        Input("filtro-fechas",   "start_date"),
        Input("filtro-fechas",   "end_date"),
    ) do tab, paises, segmentos, categorias, pagos, fecha_ini, fecha_fin

        df = df_global

        # Aplicar filtros
        if !isnothing(paises) && !isempty(paises)
            df = filter(r -> r.Country in paises, df)
        end
        if !isnothing(segmentos) && !isempty(segmentos)
            df = filter(r -> r.Customer_Segment in segmentos, df)
        end
        if !isnothing(categorias) && !isempty(categorias)
            df = filter(r -> r.Product_Category in categorias, df)
        end
        if !isnothing(pagos) && !isempty(pagos)
            df = filter(r -> r.Payment_Method in pagos, df)
        end
        if !isnothing(fecha_ini) && !isnothing(fecha_fin)
            d1 = Dates.Date(fecha_ini[1:10])
            d2 = Dates.Date(fecha_fin[1:10])
            df = filter(r -> d1 <= r.Date <= d2, df)
        end

        if nrow(df) == 0
            aviso = html_div("⚠️ Sin datos con los filtros seleccionados.",
                             style=Dict("color" => "orange", "padding" => "20px"))
            return ([], aviso)
        end

        # KPIs
        total_ingresos   = sum(df.Total_Amount)
        total_unidades   = sum(df.Total_Purchases)
        ticket_promedio  = total_ingresos / nrow(df)
        n_transacciones  = nrow(df)

        kpi_style = Dict("backgroundColor" => "#ffffff",
                         "padding" => "15px 20px",
                         "borderRadius" => "10px",
                         "flex" => "1",
                         "textAlign" => "center",
                         "boxShadow" => "0 2px 4px rgba(0,0,0,0.08)")

        kpis = [
            html_div(style=kpi_style) do
                html_p("Ingresos Totales", style=Dict("margin" => "0", "fontSize" => "12px", "color" => "#888")),
                html_h3("\$$(round(total_ingresos/1e6, digits=2))M",
                        style=Dict("margin" => "4px 0 0 0", "color" => "#1f77b4"))
            end,
            html_div(style=kpi_style) do
                html_p("Unidades Vendidas", style=Dict("margin" => "0", "fontSize" => "12px", "color" => "#888")),
                html_h3("$(round(Int, total_unidades))",
                        style=Dict("margin" => "4px 0 0 0", "color" => "#1f77b4"))
            end,
            html_div(style=kpi_style) do
                html_p("Ticket Promedio", style=Dict("margin" => "0", "fontSize" => "12px", "color" => "#888")),
                html_h3("\$$(round(ticket_promedio, digits=2))",
                        style=Dict("margin" => "4px 0 0 0", "color" => "#1f77b4"))
            end,
            html_div(style=kpi_style) do
                html_p("Transacciones", style=Dict("margin" => "0", "fontSize" => "12px", "color" => "#888")),
                html_h3("$(n_transacciones)",
                        style=Dict("margin" => "4px 0 0 0", "color" => "#1f77b4"))
            end,
        ]

        # ─── Contenido por pestaña ─────────────────────────────────────────────
        contenido = if tab == "tab-resumen"
            tendencia = combine(groupby(df, :Month_Year), :Total_Amount => sum => :Total)
            sort!(tendencia, :Month_Year)
            fig_tend = _fig_linea(tendencia, :Month_Year, :Total;
                titulo="Evolución de Ingresos Mensuales",
                xlabel="Mes", ylabel="Ventas (\$)")

            metodos = combine(groupby(df, :Payment_Method), :Total_Amount => sum => :Total)
            fig_metodo = _fig_torta(metodos.Payment_Method, metodos.Total;
                titulo="Ventas por Método de Pago")

            categ = combine(groupby(df, :Product_Category), :Total_Amount => sum => :Total)
            sort!(categ, :Total)
            fig_categ = _fig_barras_h(categ.Product_Category, categ.Total;
                titulo="Ingresos por Categoría de Producto",
                xlabel="Ventas (\$)", ylabel="Categoría",
                color="#1f77b4")

            html_div() do
                html_h3("Tendencia Histórica de Ventas"),
                dcc_graph(figure=fig_tend),
                html_div(style=Dict("display" => "flex", "gap" => "20px")) do
                    html_div(style=Dict("flex" => "1")) do
                        html_h4("Ventas por Método de Pago"),
                        dcc_graph(figure=fig_metodo)
                    end,
                    html_div(style=Dict("flex" => "1")) do
                        html_h4("Ingresos por Categoría"),
                        dcc_graph(figure=fig_categ)
                    end
                end
            end

        elseif tab == "tab-productos"
            top10 = combine(groupby(df, :products), :Total_Purchases => sum => :Total)
            sort!(top10, :Total, rev=true)
            top10 = first(top10, 10)
            sort!(top10, :Total)
            fig_top = _fig_barras_h(top10.products, top10.Total;
                titulo="Top 10 Productos Más Vendidos (Unidades)",
                xlabel="Unidades", ylabel="Producto", color="#440154")

            muestra = df[1:min(2000, nrow(df)), :]
            fig_disp = _fig_dispersion(muestra, :Total_Purchases, :Total_Amount,
                :Product_Category; titulo="Muestra: Cantidad vs Monto")

            html_div() do
                html_h3("Rendimiento de Productos"),
                dcc_graph(figure=fig_top),
                html_h3("Correlación: Cantidad vs Monto"),
                dcc_graph(figure=fig_disp)
            end

        elseif tab == "tab-clientes"
            if "Income" in names(df) && "Gender" in names(df)
                ing_gen = combine(groupby(df, [:Income, :Gender]), :Total_Amount => sum => :Total)
                fig_ing = _fig_barras_agrupadas(ing_gen, :Income, :Total, :Gender;
                    titulo="Ventas por Género y Nivel de Ingreso")
            else
                fig_ing = PlotlyJS.plot(PlotlyJS.scatter())
            end

            seg = combine(groupby(df, :Customer_Segment), :Total_Amount => sum => :Total)
            fig_seg = _fig_torta(seg.Customer_Segment, seg.Total;
                titulo="Distribución por Segmento de Cliente")

            fig_edad = if "Age" in names(df)
                _fig_histograma(df, :Age; titulo="Distribución de Edad de Compradores", nbins=20)
            else
                PlotlyJS.plot(PlotlyJS.scatter())
            end

            html_div() do
                html_div(style=Dict("display" => "flex", "gap" => "20px")) do
                    html_div(style=Dict("flex" => "1")) do
                        html_h4("Ventas por Género e Ingreso"),
                        dcc_graph(figure=fig_ing)
                    end,
                    html_div(style=Dict("flex" => "1")) do
                        html_h4("Distribución por Segmento"),
                        dcc_graph(figure=fig_seg)
                    end
                end,
                html_h3("Distribución de Edad"),
                dcc_graph(figure=fig_edad)
            end

        else  # tab-geografia
            geo = combine(groupby(df, :Country), :Total_Amount => sum => :Total_Amount)
            fig_mapa = _fig_mapa(geo; titulo="Mapa de Calor de Ventas Globales")

            html_div() do
                html_h3("Desempeño Global por País"),
                dcc_graph(figure=fig_mapa)
            end
        end

        return (kpis, contenido)
    end

    @info "Iniciando dashboard en http://$host:$port"
    run_server(app, host, port; debug=false)
end

end
