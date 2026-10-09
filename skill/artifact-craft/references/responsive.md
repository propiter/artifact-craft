# Responsive de verdad: celular, tablet y escritorio

"Se lee en el teléfono" es la regla de la barra de calidad que más se rompe. Esta referencia dice
**cómo** se cumple y **cómo se comprueba con números**, no a ojo. Sale de un caso real: un informe
mensual generado por un motor pensado para PDF A4, que en el celular se veía como un PDF achicado.

## Las cuatro causas, en orden de frecuencia

1. **Falta `<meta name="viewport" content="width=device-width, initial-scale=1">`.** Sin esa línea el
   celular dibuja la página a **980 px** y la achica entera: todo se ve "bien" en miniatura y nada se
   lee. Es una línea, y casi siempre es la causa principal. Agregá también
   `<meta name="color-scheme" content="light">` si la página tiene fondo claro fijo, para que el modo
   oscuro forzado del navegador no invierta tus colores.
2. **SVG de ancho fijo con texto adentro.** Un `viewBox="0 0 700 …"` con `width="100%"` se encoge
   proporcionalmente: un texto de 9,6 px queda en ~5 px a 390 de ancho. Sirve para formas (donas,
   barras apiladas sin rótulos) y no sirve para gráficos con etiquetas.
   - **Barras horizontales → HTML/CSS**, no SVG: una grilla `etiqueta | barra | valor`, con el ancho
     de la barra en `calc((100% - 80px) * proporción)`. Bajo 640 px la etiqueta pasa arriba de la barra.
   - **Gráficos con ejes → dibujá dos versiones** (ancha y angosta, cada una con sus proporciones y
     rótulos de eje legibles) y mostrá una con CSS (`.vw` / `.vn` + `@media`). No escales la ancha.
3. **Tablas de muchas columnas.** No entran en 390 px y el scroll horizontal es justo lo que la barra
   de calidad prohíbe. Bajo 640 px **cada fila pasa a ser una tarjeta**: `thead` oculto, `td` en
   `display:flex; justify-content:space-between`, y la cabecera de cada celda sale de un atributo
   `data-label` vía `td::before { content: attr(data-label) }`. La primera celda es el título de la
   tarjeta; `td:empty` se oculta (celdas vacías del pie). Esto exige generar `data-label` en cada
   celda: hacelo en la función que arma la tabla, una vez, no a mano.
4. **Tipos en `pt` pensados para papel.** 8–9 pt se leen en A4 y no en pantalla. Usá
   `@media screen` para pasar a px (cuerpo 14–15 px, tablas 13–14 px, rótulos ≥ 11 px) y no toques la
   impresión.

## Si la página también se imprime (PDF)

Todo lo de pantalla va dentro de `@media screen`: el A4 queda idéntico. Dos efectos colaterales que
aparecen al cambiar SVG por HTML, porque el contenido queda más compacto y se mueven los saltos de
página:

- **Títulos huérfanos al pie de página.** `break-after: avoid` en el párrafo de apertura **Chrome no lo
  respeta**. Lo que sí funciona es `section { break-inside: avoid }`: si la sección entra en una
  página se mueve entera, y si es más larga Chrome la corta igual.
- Compará el PDF antes y después (`pdfinfo` para páginas y tamaño, `pdftotext -f N -l N` para ver qué
  sección arranca en cada página). Que pase de 5 a 6 páginas para evitar huérfanos está bien.

## Cómo se comprueba (no a ojo)

Medí en **tres anchos**: 360 o 390 (celular), 768 (tablet) y 1366 (escritorio), con
`Emulation.setDeviceMetricsOverride` (`mobile: true` en los dos primeros). En cada ancho:

```js
(() => { const W = innerWidth; let desbordes = 0, chicos = 0;
  document.querySelectorAll('body *').forEach(e => {
    const r = e.getBoundingClientRect();
    if (r.width && r.right > W + 1 && getComputedStyle(e).display !== 'none') desbordes++;
    if ([...e.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())
        && e.getClientRects().length && e.tagName !== 'text'
        && parseFloat(getComputedStyle(e).fontSize) < 11) chicos++;
  });
  return { W, scrollW: document.documentElement.scrollWidth, desbordes, texto_menor_11px: chicos };
})()
```

Criterio de aprobado: `scrollW === W`, `desbordes === 0`, `texto_menor_11px === 0`. El texto de SVG
(`<text>`) se excluye porque su tamaño efectivo depende de la escala; para esos mirá la captura.
Después **mirá las capturas** de las secciones con gráficos y tablas: los números dicen que no
desborda, la captura dice si se entiende.

Repetí la medición **sobre la URL publicada**, no solo sobre el archivo local: lo que importa es lo
que abre el destinatario.
