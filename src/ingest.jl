module Ingest

using HTTP, JSON3, ZipFile, Logging, Base64
using ..Config: DATOS_BRUTOS

function descargar_datos(
    dataset_kaggle::String = "sahilprajapati143/retail-analysis-large-dataset",
    carpeta_destino::String = DATOS_BRUTOS
)::Bool
    @info "Iniciando descarga de $dataset_kaggle."

    mkpath(carpeta_destino)

    # Leer credenciales de Kaggle desde ~/.kaggle/kaggle.json
    kaggle_json = joinpath(homedir(), ".kaggle", "kaggle.json")
    if !isfile(kaggle_json)
        @error "No se encontró kaggle.json en ~/.kaggle/ — configure sus credenciales de Kaggle."
        return false
    end

    credentials = JSON3.read(read(kaggle_json, String))
    username = string(credentials[:username])
    key      = string(credentials[:key])
    @info "Conexión con Kaggle exitosa."

    # Construir URL de descarga de la API de Kaggle
    partes  = split(dataset_kaggle, "/")
    owner   = partes[1]
    dataset = partes[2]
    url     = "https://www.kaggle.com/api/v1/datasets/download/$owner/$dataset"

    zip_path = joinpath(carpeta_destino, "$dataset.zip")
    @info "Bajando archivos..."
    try
        token    = base64encode("$username:$key")
        response = HTTP.get(url, ["Authorization" => "Basic $token"]; redirect=true)
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
