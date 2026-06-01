module Ingest

using HTTP, ZipFile, Logging
using ..Config: DATOS_BRUTOS, kaggle_token

function descargar_datos(
    dataset_kaggle::String = "sahilprajapati143/retail-analysis-large-dataset",
    carpeta_destino::String = DATOS_BRUTOS
)::Bool
    @info "Iniciando descarga de $dataset_kaggle."

    mkpath(carpeta_destino)

    token = try
        kaggle_token()
    catch e
        @error "No se pudo obtener el token de Kaggle: $e"
        return false
    end
    @info "Conexión con Kaggle exitosa."

    # Construir URL de descarga de la API de Kaggle
    partes  = split(dataset_kaggle, "/")
    owner   = partes[1]
    dataset = partes[2]
    url     = "https://www.kaggle.com/api/v1/datasets/download/$owner/$dataset"

    zip_path = joinpath(carpeta_destino, "$dataset.zip")
    @info "Bajando archivos..."
    try
        response = HTTP.get(url, ["Authorization" => "Bearer $token"]; redirect=true)
        write(zip_path, response.body)
        @info "Archivo descargado: $(basename(zip_path))"
    catch e
        @error "Fallo en la descarga: $e"
        return false
    end

    # Extraer el ZIP y eliminar el archivo comprimido
    @info "Descomprimiendo $(basename(zip_path))..."
    try
        r = ZipFile.Reader(zip_path)
        nombres = String[]
        for f in r.files
            out_path = joinpath(carpeta_destino, f.name)
            write(out_path, read(f))
            push!(nombres, f.name)
        end
        close(r)
        @info "Archivos extraídos: $(join(nombres, ", "))"

        rm(zip_path)
        @info "Archivo ZIP eliminado."
        return true
    catch e
        @error "Error en la extracción: $e"
        return false
    end
end

end
