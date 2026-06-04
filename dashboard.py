import os
import streamlit as st
import pandas as pd
import plotly.express as px

# Configuración del dashboard
st.set_page_config(
    page_title="Salesight",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Estilos de CSS
st.markdown("""
    <style>
        .main {
            background-color: #f5f7f9;
        }
        .stMetric {
            background-color: #ffffff;
            padding: 15px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }
        div[data-testid="stMetricValue"] {
            color: #1f77b4;
        }
    </style>
    """,
    unsafe_allow_html=True)

# T[itulo y descripción del dashboard
st.title("📊 SaleSight: Análisis de Ventas Retail")
st.markdown("Dashboard interactivo para el monitoreo de KPIs y tendencias comerciales globales.")

# Cargar datos
@st.cache_data
def cargar_datos():
    ruta_csv = os.path.join(os.path.dirname(__file__), "data", "processed", "processed_data.csv")
    df = pd.read_csv(ruta_csv)

    # Conversión de fechas
    if 'Date' in df.columns:
        df['Date'] = pd.to_datetime(df['Date'])
    elif 'Order Date' in df.columns:
        df['Order Date'] = pd.to_datetime(df['Order Date'])
        df['Date'] = df['Order Date']

    # Eliminación de nulos
    df = df.dropna(subset=['Year'])
    df['Year'] = df['Year'].astype(int)

    # Asegurar que las columnas categóricas sean strings
    columnas_a_str = ['products', 'Product_Category', 'Product_Brand', 'Gender', 'Payment_Method', 'Country', 'Customer_Segment']
    for columna in columnas_a_str:
        if columna in df.columns:
            df[columna] = df[columna].astype(str)

    # Crear columna de mes-año para tendencias más precisas
    if 'Date' in df.columns:
        df['Month_Year'] = df['Date'].dt.to_period('M').astype(str)
    
    return df

try:
    with st.spinner('Cargando los datos...'):
        df = cargar_datos()
except Exception as e:
    st.error(f"Error crítico al cargar el dataset: {e}")
    st.stop()


# Sidebar con filtros avanzados
st.sidebar.image("https://img.icons8.com/fluency/96/000000/sales-performance.png", width=100)
st.sidebar.header("Panel de Filtros")

# Filtros de segmentos y geográfico
with st.sidebar.expander("Filtros Geográficos y Segmentos", expanded=True):
    paises = sorted(df['Country'].unique().tolist())
    paises_seleccionados = st.multiselect("Países", paises, default=paises[:5])

    segmentos = sorted(df['Customer_Segment'].unique().tolist())
    segmentos_seleccionados = st.multiselect("Segmento de Cliente", segmentos, default=segmentos)

# Filtros de producto y pago
with st.sidebar.expander("Filtros de Producto y Métodos de pago"):
    categorias_producto = sorted(df['Product_Category'].unique().tolist())
    categoias_seleccionadas = st.multiselect("Categorías", categorias_producto, default=categorias_producto)

    metodos_pago = sorted(df['Payment_Method'].unique().tolist())
    metodos_seleccionados = st.multiselect("Métodos de Pago", metodos_pago, default=metodos_pago)

# Filtro de Fecha (Rango)
fecha_minima = df['Date'].min().date()
fecha_maxima = df['Date'].max().date()
rango_fechas = st.sidebar.date_input("Rango de Fechas", [fecha_minima, fecha_maxima], min_value=fecha_minima, max_value=fecha_maxima)

# Aplicar los filtros
filtros = (
    (df['Date'].dt.date >= rango_fechas[0]) &
    (df['Date'].dt.date <= (rango_fechas[1] if len(rango_fechas) > 1 else rango_fechas[0])) &
    (df['Country'].isin(paises_seleccionados)) &
    (df['Customer_Segment'].isin(segmentos_seleccionados)) &
    (df['Product_Category'].isin(categoias_seleccionadas)) &
    (df['Payment_Method'].isin(metodos_seleccionados))
)

df_filtrado = df[filtros]

# En caso de que el df filtrado esté vacío
if df_filtrado.empty:
    st.warning("⚠️ No hay datos que coincidan con los filtros seleccionados. Por favor, ajusta tu selección.")
    st.stop()

# Layout principal
tab_resumen, tab_productos, tab_clientes, tab_geografia = st.tabs([
    "📈 Resumen Ejecutivo", 
    "📦 Análisis de Productos", 
    "👥 Perfil del Cliente", 
    "🌍 Análisis Geográfico"
])

# Tab de resumen ejecutivo
with tab_resumen:
    # KPIs superiores
    col1, col2, col3, col4 = st.columns(4)

    ganancia_total = df_filtrado['Total_Amount'].sum()
    unidades_totales = df_filtrado['Total_Purchases'].sum()
    ticket_promedio = ganancia_total / len(df_filtrado) if len(df_filtrado) > 0 else 0
    total_transacciones = len(df_filtrado)

    col1.metric("Ingresos Totales", f"${ganancia_total/1e6:,.2f}M")
    col2.metric("Unidades Vendidas", f"{unidades_totales:,.0f}")
    col3.metric("Ticket promedio", f"${round(ticket_promedio, 2)}")
    col4.metric("Transacciones", f"{round(total_transacciones):,}")

    st.markdown("---")

    # Gráfico de tendencia temporal
    st.subheader("Tendencia histórica de ventas")
    tendencia = df_filtrado.groupby('Month_Year')['Total_Amount'].sum().reset_index()
    grafico_tendencia = px.line(tendencia, x='Month_Year', y='Total_Amount',
                                title="Evolución de Ingresos Mensuales",
                                labels={'Total_Amount':'Ventas ($)', 'Month_Year':'Mes'},
                                markers=True, line_shape='spline', color_discrete_sequence=['#1f77b4'])
    st.plotly_chart(grafico_tendencia, use_container_width=True)

    # Distribución de métodos de pago y categorías
    c1, c2 = st.columns(2)
    with c1:
        st.subheader("Ventas por método de pago")
        metodo = df_filtrado.groupby('Payment_Method')['Total_Amount'].sum().reset_index()
        grafico_metodo = px.pie(metodo, values='Total_Amount', names='Payment_Method',
                                color_discrete_sequence=px.colors.qualitative.Pastel)
        st.plotly_chart(grafico_metodo, use_container_width=True)

    with c2:
        st.subheader("Ingresos por categoría de producto")
        categoria = df_filtrado.groupby('Product_Category')['Total_Amount'].sum().sort_values().reset_index()
        grafico_categoria = px.bar(categoria, x='Total_Amount', y='Product_Category', orientation='h',
                                   color='Total_Amount', color_continuous_scale='Blues')
        st.plotly_chart(grafico_categoria, use_container_width=True)

# Tab de análisis de productos
with tab_productos:
    st.subheader("Rendimiento de marcas y productos")

    col_p1, col_p2 = st.columns([2, 1])

    with col_p1:
        top_10_productos = df_filtrado.groupby('products')['Total_Purchases'].sum().nlargest(10).reset_index()
        grafico_top_productos = px.bar(top_10_productos, x='Total_Purchases', y='products', orientation='h',
                                       title="Top 10 productos más vendidos (Unidades)",
                                       color='Total_Purchases', color_continuous_scale='Viridis')
        grafico_top_productos.update_layout(yaxis={'categoryorder':'total ascending'})
        st.plotly_chart(grafico_top_productos, use_container_width=True)
    
    with col_p2:
        st.write("Marcas con mayor facturacion")
        marca = df_filtrado.groupby('Product_Brand')['Total_Amount'].sum().nlargest(10).reset_index()
        st.table(marca.style.format({'Total_Amount': '${:,.2f}'}))
    
    # Análisis de correlación unidades vs monto
    st.subheader("Correlación: Cantidad vs Monto por Transacción")
    grafico_dispersion = px.scatter(df_filtrado.sample(min(2000, len(df_filtrado))),
                                    x='Total_Purchases', y='Total_Amount',
                                    color='Product_Category', hover_name='products',
                                    opacity=0.6, title="Muestra de Transacciones")
    st.plotly_chart(grafico_dispersion, use_container_width=True)

# Tab perfil de cliente
with tab_clientes:
    st.subheader("Análisis demográfico y de comportamiento")

    col_c1, col_c2 = st.columns(2)

    with col_c1:
        st.write("Ventas por género y nivel de ingreso")
        
        # Gráfico de genero e ingresos
        ingresos_genero = df_filtrado.groupby(['Income', 'Gender'])['Total_Amount'].sum().reset_index()
        grafico_ingresos_genero = px.bar(ingresos_genero, x='Income', y='Total_Amount', color='Gender', barmode='group',
                                         category_orders={"Income": ["Bajo", "Medio", "Alto"]})
        st.plotly_chart(grafico_ingresos_genero, use_container_width=True)
    
    with col_c2:
        st.write("Distribución por segmento de cliente")
        segmento = df_filtrado.groupby('Customer_Segment')['Total_Amount'].sum().reset_index()
        grafico_segmento = px.pie(segmento, values='Total_Amount', names='Customer_Segment',
                                  color_discrete_sequence=px.colors.qualitative.Safe)
        st.plotly_chart(grafico_segmento, use_container_width=True)
    
    # Distribución de edad
    st.subheader("Distribución de edad de los compradores")
    grafico_edad = px.histogram(df_filtrado, x='Age', nbins=20, color_discrete_sequence=['#2ecc71'], marginal="box")
    st.plotly_chart(grafico_edad, use_container_width=True)

# Tab análisis geográfico
with tab_geografia:
    st.subheader("Desempeño global por país")

    geografia = df_filtrado.groupby('Country')['Total_Amount'].sum().reset_index()

    # Mapa de calor de ventas por pais
    grafico_mapa = px.choropleth(geografia, locations='Country', locationmode='country names',
                                 color='Total_Amount', hover_name='Country',
                                 title="Mapa de calor de ventas globales")
    grafico_mapa.update_layout(height=600)
    st.plotly_chart(grafico_mapa, use_container_width=True)

    # Tabla de rankings por país
    st.write("Ranking detallado por país")
    tabla_geografica = df_filtrado.groupby('Country').agg({
        'Total_Amount': 'sum',
        'Total_Purchases': 'sum',
        'Transaction_ID': 'count'
    }).rename(columns={'Transaction_ID': 'Transacciones'}).sort_values('Total_Amount', ascending=False)

    st.dataframe(tabla_geografica.style.format({'Total_Amount': '${:,.2f}', 'Total_Purchases':'{:,.0f}'}), use_container_width=True)