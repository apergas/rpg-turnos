# Migración desde la UI actual

## De los valores actuales a los tokens

| Hoy en el código | Token | Cambio |
| --- | --- | --- |
| `Color(0.04, 0.04, 0.12, 0.9)` (make_window, botón ☰) | `surface-window` | — |
| `UiStyle.TITLE_COLOR`, `SPEAKER_COLOR`, `HEADING_COLOR`, `TARGET_NAME_COLOR`, `QUEST_MARK_COLOR` | `text-accent` / `quest-mark` | cinco dorados se unen en uno |
| `StatBar.GOLD`, marca de tienda | `text-money` / `map-shop` | — |
| Título y rótulo `Color(1, 0.9, 0.45)` | `text-display` | — |
| `UiStyle.GREY` #9999a6 | `text-secondary` #b8b8cc | más legible (10:1) |
| gris desactivado #80808c | `text-disabled` | — |
| `StatBar.HP` / `MP` | `stat-hp` / `stat-mp` | — |
| `StatBar.EXP` #2e9e42 | `stat-exp` #237a33 | más oscuro: el blanco encima pasa 4,5:1 |
| `StatBar.EXP_TEXT` | `text-positive` | — |
| `ShopWindow.BETTER` / `WORSE` | `text-positive` / `text-negative` | rojo más claro sobre azul |
| Insignias de `BattleHud.BADGES` | `status-*` | + `status-stun` nueva |
| `MapMarks.COLORS` | `map-*` | — |
| Foco del tema por defecto (recuadro blanco 75 %) | `surface-selected` + cursor `border-focus` | se ve también en móvil |
| `WINDOW_MARGIN` 14 × 10 | `space-4` × `space-3` (16 × 12) | un poco más de aire |
| Tamaños 16…96 sueltos | 10 estilos de tipo | 22 → 20, 28 → 26, 44 → 48, 72 → 64 |
| Letra por defecto del motor | Nunito + Baloo 2 | igual en todas las plataformas |
| Contornos 4, 6, 8, 10, 12, 18 | `outline-s/m/l/xl` (4, 8, 12, 18) | 6 → 8, 10 → 12 |

## Orden propuesto

1. **Fuente de verdad.** Añadir `UiTokens` y `UiTheme` y aplicar el tema. No cambia nada visible si se mapean los valores de hoy, y a partir de ahí todo cambio es de un solo sitio.
2. **Cursor y fila elegida.** La mejora de UX más visible, sobre todo en móvil.
3. **Tipografía.** Incluir las dos letras y pasar a los 10 estilos.
4. **Accesibilidad.** Barra de EXP más oscura, texto secundario más claro, sombra de ventana y opción «Alto contraste».
5. **Componentes nuevos.** Notice con tono, OptionRow con deslizadores y selectores con estilo, insignia de Aturdido, PV críticos, indicador de «sigue» en el diálogo.

Cada paso se puede hacer y revisar por separado, en la sesión donde se desarrolla el juego.
