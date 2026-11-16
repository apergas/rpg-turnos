# Ideas

Registro de ideas para Villaclaro. Cada idea se apunta tal cual llega, con su fecha, sin plan ni compromiso. Cuando una idea pasa a un spec y al [documento maestro](documento-maestro.md), se borra de aquí.

Formato de cada entrada:

```
## AAAA-MM-DD · Título corto
Idea en una o pocas frases, con las palabras del usuario.
```

---

## 2026-11-16 · Capa de Villaclaro del design system fuera de docs
La capa de Villaclaro del design system vive en `docs/boost/design-system/`: su `tokens.json`, que lee el generador de tokens, y sus documentos (identidad, voz, paleta, componentes). El núcleo común es el submódulo `addons/design_system/`. Tener datos que lee el generador dentro de `docs/` confunde: mover esa capa a una carpeta propia en la raíz (por ejemplo `design/`), cambiando las rutas de `design_system.json` y todo lo que apunte allí (CLAUDE.md, las rutas vigiladas por el hook, los enlaces).
