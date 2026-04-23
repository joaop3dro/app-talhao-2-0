# app-talhao-2-0

> Aplicativo mobile para **demarcação e gestão de talhões agrícolas** desenvolvido em **Delphi 12 FMX** com banco de dados local SQLite.

## 📱 Sobre o Projeto

O **TalhãoMap** nasceu da necessidade de produtores rurais de demarcarem suas áreas de produção diretamente no campo, usando apenas o celular. O aplicativo permite desenhar os limites de um talhão tocando no mapa, calcula automaticamente a **área em hectares** e o **perímetro em quilômetros**, e salva tudo localmente sem depender de internet.

Inspirado no [GPS Fields Area Measure](https://play.google.com/store/apps/details?id=lt.noframe.fieldsareameasure), o TalhãoMap foi construído do zero em Delphi FMX para Android e iOS, com uma versão de desenvolvimento para Windows via WebBrowser.

## ✨ Funcionalidades

| Funcionalidade | Descrição |
|---|---|
| 🗺️ Desenho de talhão | Toque no mapa para adicionar vértices do polígono |
| 📐 Cálculo automático | Área (ha) e perímetro (km) calculados em tempo real |
| 📏 Distância por segmento | Cada trecho do polígono exibe sua distância |
| 🔄 Redimensionamento | Arraste os vértices para ajustar a área após fechar |
| 📍 GPS integrado | Centraliza o mapa na localização atual do dispositivo |
| 💾 Banco local SQLite | Dados salvos no dispositivo via FireDAC + SQLite |
| 🔍 Consulta de talhões | Lista com busca por nome e filtro por grupo |
| 👁️ Visualização limpa | Modo de consulta exibe o polígono sem marcadores |
| 🗂️ Agrupamento | Organize talhões em grupos personalizados |
| ✏️ Edição | Edite nome, grupo, descrição e redesenhe o talhão |

## 🗺️ Tecnologia de Mapas

### Android / iOS — `TMapView` (nativo FMX)
- Geolocalização via `TLocationSensor` com permissão em runtime (Android 6+)
- Polígonos via `TMapPolygon`, polylines via `TMapPolyline`, marcadores via `TMapMarker`

## 📐 Cálculos Geográficos

Implementados em `TTalhao.CalcularAreaEPerimetro` (`models.pas`):

- **Área:** Algoritmo de Shoelace com correção por `cos(latitude_média)` → **hectares**
- **Perímetro:** Fórmula de Haversine segmento a segmento → **km**
- **Distância por segmento:** Haversine entre cada par de vértices adjacentes

### Pré-requisitos

| Ferramenta | Versão |
|---|---|
| Delphi / RAD Studio | **11 Athens** ou superior |
| Android SDK | API 21+ (Android 5.0) |
| iOS SDK | iOS 14+ |

### 3. Configurar API Key 

1. Acesse [Google Cloud Console](https://console.cloud.google.com)
2. Crie um projeto e ative **Maps SDK**
3. Gere uma API Key 
4. No Delphi: `Project > Options > Version Info > apiKey`

### 4. Configurar permissões — iOS

Em `Project > Options > Version Info`, adicione:

```
NSLocationWhenInUseUsageDescription = Necessário para localizar sua posição no talhão
```

## 📲 Fluxo do Aplicativo

```
Tela Principal
    │
    ├── [+ Novo Talhão]
    │       └── TMapView (mobile) / WebBrowser (Windows)
    │               ├── Toque no mapa → adiciona vértice
    │               ├── Distância exibida em cada segmento
    │               ├── Arrastar vértice → redimensiona área
    │               ├── Fechar Polígono → calcula área e perímetro
    │               └── Salvar → grava no SQLite
    │
    └── [Consultar Talhões]
            ├── Lista com busca e filtro por grupo
            ├── Swipe para excluir
            └── Toque no item → visualiza polígono no mapa (sem pings)
```

<div align="center">
  Feito com ☕ e Delphi FMX
</div>
