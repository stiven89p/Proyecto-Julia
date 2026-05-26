module Features

using DataFrames, CSV, Dates, Statistics, Logging
using ..Dataset: obtener_datos_raw

# Convierte un valor a Float64 o devuelve missing si no es posible
function _a_float(x)::Union{Float64, Missing}
    ismissing(x) && return missing
    v = tryparse(Float64, string(x))
    isnothing(v) ? missing : v
end

# Convierte un valor a Date o devuelve missing si no es posible
function _a_fecha(x)::Union{Date, Missing}
    ismissing(x) && return missing
    s = string(x)
    v = tryparse(Date, s)
    isnothing(v) || return v
    v = tryparse(Date, s, dateformat"m/d/yyyy")
    isnothing(v) ? missing : v
end

function procesar_caracteristicas(archivo_raw::String = "new_retail_data.csv")::Union{DataFrame, Nothing}
    @info "Iniciando transformación de datos..."

    df = obtener_datos_raw(archivo_raw)
    if isnothing(df)
        @error "No se pudieron cargar los datos para transformar."
        return nothing
    end

    # Eliminar filas donde TODOS los valores son missing (equivalente a dropna(how='all'))
    filter!(row -> any(!ismissing(row[col]) for col in names(df)), df)

    # Convertir columnas numéricas clave a Float64
    columnas_num = ["Total_Purchases", "Amount", "Total_Amount"]
    for col in columnas_num
        if col in names(df)
            df[!, col] = _a_float.(df[!, col])
        end
    end

    # Imputación: rellenar nulos con la mediana del grupo Product_Type
    if "Product_Type" in names(df)
        for col in columnas_num
            sym = Symbol(col)
            if col in names(df) && any(ismissing, df[!, col])
                transform!(groupby(df, :Product_Type), sym => (x -> begin
                    vals = collect(skipmissing(x))
                    isempty(vals) ? x : coalesce.(x, median(vals))
                end) => sym)

                # Rellenar los que aún queden con la mediana global
                vals_global = collect(skipmissing(df[!, col]))
                if !isempty(vals_global)
                    df[!, col] = coalesce.(df[!, col], median(vals_global))
                end
            end
        end
    end

    # Rellenar Product_Type nulo con 'Unknown'
    if "Product_Type" in names(df) && any(ismissing, df[!, :Product_Type])
        df[!, :Product_Type] = coalesce.(df[!, :Product_Type], "Unknown")
    end

    # Parsear fechas y eliminar las inválidas
    if "Date" in names(df)
        df[!, :Date] = _a_fecha.(df[!, :Date])
        filter!(row -> !ismissing(row.Date), df)
    end

    @info "Transformación (T) completada. Registros: $(nrow(df))"
    return df
end

end
