module Dataset

using SQLite, DBInterface, DataFrames, CSV, Dates, Logging
using ..Config: DATOS_PROCESADOS, DATOS_BRUTOS, NOMBRE_DB

function obtener_datos_db(nombre_db::String = NOMBRE_DB)::Union{DataFrame, Nothing}
    ruta_db = joinpath(DATOS_PROCESADOS, nombre_db)
    if !isfile(ruta_db)
        @warn "La base de datos no existe en: $ruta_db"
        return nothing
    end

    @info "Conectando con la base de datos en: $ruta_db..."
    try
        db = SQLite.DB(ruta_db)
        df = DataFrame(DBInterface.execute(db, "SELECT * FROM ventas"))
        close(db)
        if "Order Date" in names(df)
            df[!, "Order Date"] = Dates.Date.(df[!, "Order Date"])
        end
        return df
    catch e
        @error "Error al acceder a la DB: $e"
        return nothing
    end
end

function obtener_datos_raw(nombre_archivo::String = "new_retail_data.csv")::Union{DataFrame, Nothing}
    ruta_csv = joinpath(DATOS_BRUTOS, nombre_archivo)
    if !isfile(ruta_csv)
        @error "No se encontró el archivo RAW en: $ruta_csv."
        return nothing
    end

    @info "Cargando datos brutos desde: $ruta_csv..."
    try
        return CSV.read(ruta_csv, DataFrame)
    catch e
        @error "Error al leer el CSV raw: $e"
        return nothing
    end
end

function guardar_datos_db(df::DataFrame, nombre_db::String = NOMBRE_DB)::Bool
    ruta_db = joinpath(DATOS_PROCESADOS, nombre_db)
    @info "Cargando datos en la base de datos: $ruta_db..."

    try
        df_db = copy(df)
        # Convertir columnas de fecha a String para compatibilidad con SQLite
        for col in names(df_db)
            T = nonmissingtype(eltype(df_db[!, col]))
            if T <: Union{Date, DateTime}
                df_db[!, col] = string.(df_db[!, col])
            end
        end

        db = SQLite.DB(ruta_db)
        SQLite.execute(db, "DROP TABLE IF EXISTS ventas")
        SQLite.load!(df_db, db, "ventas")
        close(db)
        @info "Datos guardados exitosamente en '$nombre_db'."
        return true
    catch e
        @error "Error en la persistencia: $e"
        return false
    end
end

end
