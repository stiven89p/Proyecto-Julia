import os
import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go

st.set_page_config(
    page_title="SaleSight — Reporte Ejecutivo",
    page_icon="📋",
    layout="wide"
)

st.markdown("""
<style>
    .bloque-insight {
        background-color: #eef5ff;
        border-left: 5px solid #1a6fbf;
        padding: 14px 18px;
        border-radius: 4px;
        margin: 14px 0;
        font-size: 0.97rem;
        line-height: 1.6;
    }
    .bloque-alerta {
        background-color: #fff3e0;
        border-left: 5px solid #e67e22;
        padding: 14px 18px;
        border-radius: 4px;
        margin: 14px 0;
        font-size: 0.97rem;
        line-height: 1.6;
    }
    .bloque-positivo {
        background-color: #eafaf1;
        border-left: 5px solid #27ae60;
        padding: 14px 18px;
        border-radius: 4px;
        margin: 14px 0;
        font-size: 0.97rem;
        line-height: 1.6;
    }
    h2 { margin-top: 2rem; }
</style>
""", unsafe_allow_html=True)


# ── Carga de datos ────────────────────────────────────────────────────────────
@st.cache_data
def cargar_datos():
    ruta = os.path.join(os.path.dirname(__file__), "data", "processed", "processed_data.csv")
    df = pd.read_csv(ruta)
    if "Date" in df.columns:
        df["Date"] = pd.to_datetime(df["Date"], errors="coerce")
    for col in ["Product_Category", "Country", "Customer_Segment", "Feedback", "Payment_Method"]:
        if col in df.columns:
            df[col] = df[col].astype(str)
    return df

try:
    df = cargar_datos()
except Exception as e:
    st.error(f"Error al cargar el dataset: {e}")
    st.stop()

# Calculos base
ingresos_totales = df["Total_Amount"].sum()
ticket_promedio = df["Total_Amount"].mean()
n_transacciones = len(df)

ingresos_pais = df.groupby("Country")["Total_Amount"].sum().sort_values(ascending=False)
ingresos_cat = df.groupby("Product_Category")["Total_Amount"].sum().sort_values(ascending=False)

df_clf = df.dropna(subset=["Feedback", "Ratings"]).copy()
df_clf["satisfecho_real"] = df_clf["Feedback"].isin(["Excellent", "Good"])
tasa_satisfaccion = df_clf["satisfecho_real"].mean() * 100

segmentos = df.groupby("Customer_Segment")["Total_Amount"].agg(["mean", "count"]).reset_index()
segmentos.columns = ["Segmento", "Ticket promedio", "Transacciones"]


# ══════════════════════════════════════════════════════════════════════════════
# PORTADA
# ══════════════════════════════════════════════════════════════════════════════
st.title("Reporte Ejecutivo — SaleSight")
st.markdown(
    "**Cliente:** Firma de Retail Global  |  "
    "**Periodo:** Enero 2023 – Diciembre 2024  |  "
    "**Consultor:** Stiven Posada Casadiego, Josue Ribero Duarte"
)
st.markdown("---")

st.markdown(
    '<div class="bloque-insight">'
    'Este reporte resume lo que encontramos al analizar sus datos de ventas. '
    'Cada hallazgo viene acompanado de lo que significa para su negocio y de una recomendacion concreta. '
    'No es un documento tecnico — es una guia de accion.'
    '</div>',
    unsafe_allow_html=True
)


# ══════════════════════════════════════════════════════════════════════════════
# 1. COMO VA EL NEGOCIO HOY
# ══════════════════════════════════════════════════════════════════════════════
st.header("1. Como va el negocio hoy")

k1, k2, k3, k4 = st.columns(4)
k1.metric("Ingresos totales del periodo", f"${ingresos_totales / 1e9:.2f}B USD")
k2.metric("Transacciones registradas", f"{n_transacciones:,}")
k3.metric("Gasto promedio por compra", f"${ticket_promedio:,.0f} USD")
k4.metric("Clientes satisfechos", f"{tasa_satisfaccion:.1f}%")

st.markdown("---")

col_a, col_b = st.columns(2)

with col_a:
    fig_pais = px.bar(
        ingresos_pais.reset_index(),
        x="Total_Amount", y="Country", orientation="h",
        title="Ingresos por mercado",
        labels={"Total_Amount": "Ingresos (USD)", "Country": "Pais"},
        color="Total_Amount", color_continuous_scale="Blues",
        text_auto=".2s"
    )
    fig_pais.update_layout(coloraxis_showscale=False, height=320)
    st.plotly_chart(fig_pais, use_container_width=True)

with col_b:
    fig_cat = px.bar(
        ingresos_cat.reset_index(),
        x="Total_Amount", y="Product_Category", orientation="h",
        title="Ingresos por categoria de producto",
        labels={"Total_Amount": "Ingresos (USD)", "Product_Category": "Categoria"},
        color="Total_Amount", color_continuous_scale="Greens",
        text_auto=".2s"
    )
    fig_cat.update_layout(coloraxis_showscale=False, height=320)
    st.plotly_chart(fig_cat, use_container_width=True)

st.markdown(
    '<div class="bloque-positivo">'
    'El negocio opera de forma estable en todos los mercados y todas las categorias. '
    'No hay un mercado o producto dominante que concentre el riesgo — los ingresos estan '
    'bien distribuidos. Esto es una fortaleza.'
    '</div>',
    unsafe_allow_html=True
)


# ══════════════════════════════════════════════════════════════════════════════
# 2. LO QUE MAS NOS PREOCUPA
# ══════════════════════════════════════════════════════════════════════════════
st.header("2. Lo que mas nos preocupa")

col_c, col_d = st.columns(2)

with col_c:
    st.subheader("Sus clientes Premium no se comportan como Premium")

    fig_seg = px.bar(
        segmentos.sort_values("Ticket promedio"),
        x="Ticket promedio", y="Segmento", orientation="h",
        title="Gasto promedio por tipo de cliente",
        labels={"Ticket promedio": "Gasto promedio por compra (USD)"},
        color="Segmento",
        color_discrete_sequence=["#3498db", "#e67e22", "#2ecc71"]
    )
    fig_seg.update_layout(showlegend=False, height=280)
    st.plotly_chart(fig_seg, use_container_width=True)

    st.markdown(
        '<div class="bloque-alerta">'
        'Un cliente Premium gasta en promedio <strong>$1,363 USD</strong> por compra. '
        'Un cliente nuevo gasta <strong>$1,368 USD</strong>. La diferencia es de <strong>$5</strong> — '
        'practicamente cero. Su programa de segmentacion no esta generando comportamientos de compra '
        'distintos. Hoy, un cliente "Premium" y uno nuevo son indistinguibles por su nivel de gasto.'
        '</div>',
        unsafe_allow_html=True
    )

with col_d:
    st.subheader("Tres mercados concentran demasiado riesgo operacional")

    criticos = ["Australia", "Canada", "Germany"]
    vol_pais = df.groupby("Country")["Total_Amount"].sum().reset_index()
    vol_pais.columns = ["Pais", "Ingresos"]
    vol_total = vol_pais["Ingresos"].sum()
    vol_pais["Participacion (%)"] = (vol_pais["Ingresos"] / vol_total * 100).round(1)
    vol_pais["Critico"] = vol_pais["Pais"].isin(criticos)
    vol_pais = vol_pais.sort_values("Participacion (%)", ascending=True)

    fig_riesgo = px.bar(
        vol_pais, x="Participacion (%)", y="Pais", orientation="h",
        title="Participacion de cada mercado en los ingresos totales",
        color="Critico",
        color_discrete_map={True: "#e74c3c", False: "#95a5a6"},
        text="Participacion (%)"
    )
    fig_riesgo.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
    fig_riesgo.update_layout(showlegend=False, height=280, xaxis_title="Participacion (%)")
    st.plotly_chart(fig_riesgo, use_container_width=True)

    pct_criticos = vol_pais[vol_pais["Critico"]]["Participacion (%)"].sum()
    st.markdown(
        f'<div class="bloque-alerta">'
        f'<strong>Australia, Canada y Germany</strong> (marcados en rojo) representan el '
        f'<strong>{pct_criticos:.0f}%</strong> de los ingresos totales. '
        f'Si cualquiera de estos mercados enfrenta un problema operacional, regulatorio o logistico, '
        f'el impacto en el negocio es inmediato y significativo. '
        f'Actualmente no hay un plan de contingencia documentado para este escenario.'
        f'</div>',
        unsafe_allow_html=True
    )


# ══════════════════════════════════════════════════════════════════════════════
# 3. UNA OPORTUNIDAD CONCRETA
# ══════════════════════════════════════════════════════════════════════════════
st.header("3. Una oportunidad concreta")

col_e, col_f = st.columns([2, 1])

with col_e:
    df_clf["satisfecho_predicho"] = df_clf["Ratings"].astype(float) >= 4.0
    vp = int(((df_clf["satisfecho_real"]) & (df_clf["satisfecho_predicho"])).sum())
    vn = int(((~df_clf["satisfecho_real"]) & (~df_clf["satisfecho_predicho"])).sum())
    fp = int(((~df_clf["satisfecho_real"]) & (df_clf["satisfecho_predicho"])).sum())
    fn = int(((df_clf["satisfecho_real"]) & (~df_clf["satisfecho_predicho"])).sum())
    total_clf = vp + vn + fp + fn
    exactitud = (vp + vn) / total_clf * 100

    resultado = pd.DataFrame({
        "": ["El cliente dijo que SI estaba satisfecho", "El cliente dijo que NO estaba satisfecho"],
        "La calificacion decia >= 4 (satisfecho)": [
            f"{vp:,}  -- acierto",
            f"{fp:,}  -- error"
        ],
        "La calificacion decia < 4 (insatisfecho)": [
            f"{fn:,}  -- error",
            f"{vn:,}  -- acierto"
        ]
    })
    st.write("**La calificacion numerica vs lo que el cliente realmente dijo:**")
    st.dataframe(resultado, use_container_width=True, hide_index=True)
    st.caption(f"Resultado: la calificacion numerica acierta en el {exactitud:.1f}% de los {total_clf:,} casos analizados.")

with col_f:
    st.markdown(
        f'<div class="bloque-positivo">'
        f'Hoy sus equipos revisan comentarios escritos uno por uno para saber si un cliente '
        f'quedo satisfecho. Encontramos que con solo mirar la calificacion numerica '
        f'(4 estrellas o mas = satisfecho) se acierta en el <strong>{exactitud:.1f}%</strong> de los casos. '
        f'<br><br>'
        f'Eso es suficiente para montar un sistema automatico de alerta que identifique clientes '
        f'insatisfechos en tiempo real, sin revision manual. El <strong>{100 - exactitud:.1f}%</strong> '
        f'de error residual es manejable con una revision puntual de los casos de baja calificacion.'
        f'</div>',
        unsafe_allow_html=True
    )


# ══════════════════════════════════════════════════════════════════════════════
# 4. QUE HACEMOS A CONTINUACION
# ══════════════════════════════════════════════════════════════════════════════
st.header("4. Que hacemos a continuacion")

st.markdown(
    '<div class="bloque-insight">'
    'Estas son las tres acciones que recomendamos tomar en los proximos 90 dias, '
    'en orden de impacto esperado para el negocio.'
    '</div>',
    unsafe_allow_html=True
)

acciones = pd.DataFrame({
    "Accion": [
        "Crear un plan de contingencia para Australia, Canada y Germany",
        "Redefinir que significa ser cliente Premium",
        "Activar monitoreo automatico de satisfaccion"
    ],
    "Por que es urgente": [
        f"Estos tres mercados concentran el {pct_criticos:.0f}% de los ingresos. "
        "No tener un plan de respaldo es el riesgo operacional mas alto identificado en este analisis.",
        "El programa de fidelizacion no esta diferenciando el comportamiento de compra. "
        "Se esta invirtiendo en un segmento que hoy se comporta igual que un cliente nuevo.",
        f"Con una regla simple se puede detectar el {exactitud:.1f}% de los clientes insatisfechos "
        "automaticamente. Hoy ese proceso es manual y probablemente lento."
    ],
    "Que se necesita": [
        "Identificar proveedores alternativos, rutas de distribucion de respaldo y protocolos de activacion.",
        "Definir criterios medibles: frecuencia de compra, valor acumulado en 12 meses, canal de preferencia.",
        "Configurar una alerta automatica cuando Ratings < 4 en los sistemas de gestion del cliente."
    ]
})

st.dataframe(acciones, use_container_width=True, hide_index=True)

st.markdown("---")
st.caption(
    "Reporte preparado por SaleSight — Consultoria de Datos  |  "
    "Stiven Posada Casadiego, Josue Ribero Duarte  |  2025"
)
