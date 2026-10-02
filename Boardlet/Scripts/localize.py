from pathlib import Path
import re,json
# Keep this small source dictionary reviewable; emitted strings are target resources.
rows='''
Boards|Tableros
New board|Nuevo tablero
Board|Tablero
Board name|Nombre del tablero
Board actions|Acciones del tablero
Board controls|Opciones del tablero
All boards|Todos los tableros
Pinned|Fijados
Pin|Fijar
Unpin|Desfijar
Settings|Ajustes
Recently deleted|Eliminados recientemente
Create|Crear
Cancel|Cancelar
Done|Listo
Save|Guardar
Saved|Guardado
Saving…|Guardando…
Not saved|Sin guardar
Retry save|Reintentar guardado
Retry|Reintentar
Close|Cerrar
Open|Abrir
Rename|Cambiar nombre
Duplicate|Duplicar
Copy of|Copia de
Move earlier|Mover antes
Move later|Mover después
Move to Recently deleted|Mover a eliminados recientemente
Restore|Restaurar
Choose a board|Elige un tablero
Or create a new one to get started.|O crea uno nuevo para empezar.
Search boards|Buscar tableros
No matching boards|No hay tableros coincidentes
A place for your words|Un espacio para tus palabras
Create a board with pictures, labels and a voice. Your boards stay on this device.|Crea un tablero con imágenes, etiquetas y voz. Tus tableros se guardan en este dispositivo.
Your library needs attention|Tu biblioteca necesita atención
The library could not be read.|No se pudo leer la biblioteca.
Restore previous save|Restaurar el guardado anterior
Opening your boards…|Abriendo tus tableros…
Start with|Empezar con
Blank board|Tablero vacío
First · Then|Primero · Después
Routine|Rutina
First|Primero
Then|Después
Wake up|Despertarse
Get dressed|Vestirse
Breakfast|Desayunar
Go out|Salir
You can change the pictures, labels and layout at any time.|Puedes cambiar las imágenes, etiquetas y distribución cuando quieras.
Deleted boards stay here until you restore them. Their pictures and recordings are kept.|Los tableros eliminados permanecen aquí hasta que los restaures. Se conservan sus imágenes y grabaciones.
Add|Añadir
Add cards|Añadir tarjetas
Add your first card|Añade tu primera tarjeta
Choose a symbol, a photo or your camera. You can add labels and recordings later.|Elige un símbolo, una foto o la cámara. Puedes añadir etiquetas y grabaciones después.
Selected|Seleccionado
Untitled card|Tarjeta sin título
Card actions|Acciones de tarjeta
Edit card|Editar tarjeta
Duplicate card|Duplicar tarjeta
Use as cover|Usar como portada
Use as board cover|Usar como portada del tablero
Remove|Quitar
Use|Usar
Print and share|Imprimir y compartir
Edit all labels|Editar todas las etiquetas
Done selecting|Terminar selección
Select cards|Seleccionar tarjetas
Select all|Seleccionar todo
Duplicate selection|Duplicar selección
Copy to another board|Copiar a otro tablero
Remove selection|Quitar selección
Undo|Deshacer
Redo|Rehacer
Choose cover picture|Elegir imagen de portada
Use card preview as cover|Usar vista previa de tarjetas como portada
When a card is tapped|Al tocar una tarjeta
Tap behaviour|Acción al tocar
Speak the card|Leer la tarjeta
Add to message|Añadir al mensaje
Speak and add to message|Leer y añadir al mensaje
Confirm before leaving Use mode|Confirmar antes de salir del modo de comunicación
Communication layout|Distribución para comunicar
Cards keep the same row, column and page during rotation. Small windows scroll instead of moving your choices.|Las tarjetas mantienen su fila, columna y página al girar el dispositivo. En ventanas pequeñas se desplaza el contenido sin cambiar las posiciones.
Labels|Etiquetas
Labels above pictures|Etiquetas sobre las imágenes
Voice|Voz
Label|Etiqueta
Source|Fuente
Symbols|Símbolos
Photos|Fotos
Photo|Foto
Camera|Cámara
Text|Texto
Search|Buscar
Search symbols|Buscar símbolos
Symbol language|Idioma de símbolos
English|Inglés
English (UK)|Inglés (Reino Unido)
English (US)|Inglés (Estados Unidos)
Searching…|Buscando…
Search for pictures to add to your board. Downloaded cards work offline.|Busca imágenes para añadir al tablero. Las tarjetas descargadas funcionan sin conexión.
Choose pictures from your library|Elige imágenes de tu biblioteca
Choose photos|Elegir fotos
Take a photo for a card|Haz una foto para una tarjeta
Open camera|Abrir cámara
Create a card with a label. Add a picture or a recording whenever you need one.|Crea una tarjeta con una etiqueta. Añade una imagen o una grabación cuando lo necesites.
Add a text card|Añadir tarjeta de texto
New card|Nueva tarjeta
Cancel import|Cancelar importación
Some cards could not be imported. Your successful selections are kept.|No se pudieron importar algunas tarjetas. Se conservan las selecciones que se importaron correctamente.
Retry failed items|Reintentar los elementos fallidos
Choose picture|Elegir imagen
Use picture|Usar imagen
A camera is not available on this device.|No hay cámara disponible en este dispositivo.
Allow Camera access in Settings to take a photo.|Permite el acceso a la cámara en Ajustes para hacer una foto.
Replace picture|Reemplazar imagen
Crop picture|Recortar imagen
Remove background|Quitar fondo
Restore original picture|Restaurar imagen original
Editing picture…|Editando imagen…
Card voice|Voz de la tarjeta
Voice source|Origen de la voz
Speak the label|Leer la etiqueta
Play a recording|Reproducir grabación
Silent|Silencio
Tap behaviour is set for the whole board in Board controls.|La acción al tocar se configura para todo el tablero en Opciones del tablero.
Preview voice|Escuchar voz
Recording…|Grabando…
Save recording|Guardar grabación
Cancel recording|Cancelar grabación
Record voice|Grabar voz
Replace recording|Reemplazar grabación
Remove recording|Quitar grabación
Source credits|Créditos de las fuentes
Crop area|Área de recorte
Left|Izquierda
Top|Arriba
Width|Anchura
Height|Altura
The original picture is kept. Use Restore original picture to undo image changes.|Se conserva la imagen original. Usa Restaurar imagen original para deshacer los cambios de imagen.
Apply|Aplicar
Audio was interrupted. Tap Speak to continue.|El audio se interrumpió. Pulsa Hablar para continuar.
The recording could not be played.|No se pudo reproducir la grabación.
Recording unavailable. Speaking the label instead.|Grabación no disponible. Se leerá la etiqueta.
The selected voice is unavailable. Using the system voice.|La voz seleccionada no está disponible. Se usará la voz del sistema.
Allow Microphone access in Settings to record a voice.|Permite el acceso al micrófono en Ajustes para grabar una voz.
Language|Idioma
System voice|Voz del sistema
Enhanced|Mejorada
Premium|Premium
Allow Personal Voice|Permitir Voz personal
Download additional voices in Settings → Accessibility → Spoken Content. If a voice is unavailable, Boardlet uses the system voice for the chosen language.|Descarga más voces en Ajustes → Accesibilidad → Contenido leído. Si una voz no está disponible, Boardlet usa la voz del sistema del idioma elegido.
This board has no cards yet.|Este tablero todavía no tiene tarjetas.
Previous page|Página anterior
Next page|Página siguiente
Your message|Tu mensaje
Exit Use mode|Salir del modo de comunicación
Stop speaking|Detener voz
Leave Use mode?|¿Salir del modo de comunicación?
Return to editing|Volver a editar
Keep using board|Seguir usando el tablero
Speak|Hablar
Remove last|Quitar última
Clear|Borrar
Source credits included|Créditos incluidos
Landscape|Horizontal
Portrait|Vertical
Preparing pages…|Preparando páginas…
Saving pages…|Guardando páginas…
Paper and layout|Papel y distribución
Print|Imprimir
Share PDF|Compartir PDF
Save images|Guardar imágenes
Print preview|Vista previa de impresión
Allow Photos access in Settings to save pages.|Permite el acceso a Fotos en Ajustes para guardar páginas.
All pages saved to Photos.|Todas las páginas se guardaron en Fotos.
Paper|Papel
Paper size|Tamaño del papel
Paper orientation stays the same when you rotate your device.|La orientación del papel no cambia al girar el dispositivo.
Grid|Cuadrícula
Repeat a single card to fill the page|Repetir una sola tarjeta para llenar la página
Picture margins|Márgenes de imagen
Show labels|Mostrar etiquetas
Bold labels|Etiquetas en negrita
Label size|Tamaño de etiqueta
Board title|Título del tablero
Show board title|Mostrar título del tablero
Bold board title|Título en negrita
Title size|Tamaño del título
Style|Estilo
Background|Fondo
Text colour|Color del texto
Border colour|Color del borde
Title colour|Color del título
Fitzgerald category borders|Bordes de categorías Fitzgerald
Communication defaults|Valores de comunicación
A message belongs to one Use session. Leaving Use mode clears it. Rotation and changing pages keep it.|El mensaje pertenece a una sesión de comunicación. Se borra al salir de ella. Girar o cambiar de página lo conserva.
Print defaults|Valores de impresión
Defaults apply to new boards. Existing boards keep their own settings.|Los valores se aplican a los nuevos tableros. Los existentes mantienen sus propios ajustes.
Your data|Tus datos
Import legacy boards folder|Importar carpeta de tableros anteriores
Import Boardlet backup|Importar copia de Boardlet
Export complete backup|Exportar copia completa
Choose a copy of the old app’s Documents folder, or a single board folder containing index.json and its media. Originals are never changed. Reimporting the same legacy board skips it.|Elige una copia de la carpeta Documents de la app anterior o una carpeta de tablero con index.json y sus archivos. Los originales no se modifican. Se omiten los tableros ya importados.
Importing and validating…|Importando y comprobando…
Help|Ayuda
Add pictures in the editor, then tap a card to edit its label or voice. Board controls set what happens when a card is tapped in Use mode. Card actions offer accessible move and duplicate controls. Undo and Redo restore recent edits, including removed cards.|Añade imágenes en el editor y toca una tarjeta para editar su etiqueta o voz. Opciones del tablero define la acción al tocar en comunicación. Acciones de tarjeta permite mover y duplicar de forma accesible. Deshacer y Rehacer recuperan ediciones recientes, incluidas tarjetas eliminadas.
Use mode keeps card positions stable. Swipe to scroll dense boards; use Previous page and Next page for more cards. Use Guided Access in iOS Settings for stronger session protection.|El modo de comunicación mantiene las posiciones. Desliza para ver tableros densos; usa Página anterior y Página siguiente para ver más tarjetas. Usa Acceso guiado en Ajustes de iOS para proteger la sesión.
Contact support|Contactar con soporte
Credits|Créditos
ARASAAC pictograms: Sergio Palao, Government of Aragón. Licensed under CC BY-NC-SA. Attribution is saved with each card and included in exported pages. Respect the licence when sharing.|Pictogramas ARASAAC: Sergio Palao, Gobierno de Aragón. Licencia CC BY-NC-SA. Los créditos se guardan con cada tarjeta y se incluyen en las páginas exportadas. Respeta la licencia al compartir.
Starter boards use Apple SF Symbols. Photos and recordings stay on your device. Symbol searches require an internet connection.|Los tableros iniciales usan SF Symbols de Apple. Las fotos y grabaciones se guardan en el dispositivo. La búsqueda de símbolos necesita conexión a internet.
About|Acerca de
Boardlet · Development edition|Boardlet · Edición de desarrollo
This edition uses a separate library from PECS Maker and Easy PECS Plus.|Esta edición usa una biblioteca independiente de PECS Maker y Easy PECS Plus.
Backup imported.|Copia importada.
boards imported|tableros importados
already imported|ya importados
This library was created by a newer version of Boardlet.|Esta biblioteca se creó con una versión más reciente de Boardlet.
The board data is invalid. The original files have been kept.|Los datos del tablero no son válidos. Se conservan los archivos originales.
A media path is unsafe. Import was cancelled.|Una ruta de archivo no es segura. Se canceló la importación.
A media file is missing or damaged:|Falta un archivo multimedia o está dañado:
The library could not be read. Restore the previous save or import a backup.|No se pudo leer la biblioteca. Restaura el guardado anterior o importa una copia.
Describe a symbol|Describe un símbolo
Creating symbol…|Creando símbolo…
Create with AI|Crear con IA
AI-generated image|Imagen generada con IA
Additional Plus sources|Más fuentes Plus
AI symbol creation requires an application-owned service. No service is configured in this development edition. Existing AI cards can be imported and used offline.|La creación de símbolos con IA necesita un servicio de la aplicación. Esta edición de desarrollo no tiene un servicio configurado. Las tarjetas de IA existentes se pueden importar y usar sin conexión.
Dynavox libraries require the existing licensed symbol bundle. This development edition can preserve and use imported Dynavox cards; new Dynavox searches are not yet available.|Las bibliotecas Dynavox requieren el paquete de símbolos con licencia existente. Esta edición conserva las tarjetas Dynavox importadas, pero aún no permite nuevas búsquedas.
%lld cards|%lld tarjetas
%lld across|%lld por fila
%lld rows|%lld filas
%lld rows per page|%lld filas por página
%lld selected|%lld seleccionadas
Ready to add: %lld|Listas para añadir: %lld
Download %lld selected|Descargar %lld seleccionados
Importing %lld of %lld|Importando %lld de %lld
Page %lld of %lld|Página %lld de %lld
%lld × %lld mm per card|%lld × %lld mm por tarjeta
%lld pages · %@ · %@|%lld páginas · %@ · %@
Border: %lld pt|Borde: %lld pt
Left: %lld%%|Izquierda: %lld%%
Top: %lld%%|Arriba: %lld%%
Width: %lld%%|Anchura: %lld%%
Height: %lld%%|Altura: %lld%%
'''
translations=dict(row.split('|',1) for row in rows.strip().splitlines())
keys=set(translations)
for p in Path('Boardlet/Sources').rglob('*.swift'):
 for key in re.findall(r'(?:Text|Button|Label|TextField|Section|Picker|Toggle|ProgressView|Link|L|navigationTitle|confirmationDialog|alert)\("((?:[^"\\]|\\.)*)"',p.read_text()):
  if '\\(' not in key: keys.add(key)
for language in ['en','es']:
 p=Path('Boardlet/Resources')/(language+'.lproj')/'Localizable.strings'
 p.write_text('\n'.join(json.dumps(key,ensure_ascii=False)+' = '+json.dumps(translations.get(key,key) if language=='es' else key,ensure_ascii=False)+';' for key in sorted(keys))+'\n')
print('Wrote',len(keys),'localization keys. Untranslated Spanish:',[k for k in sorted(keys) if k not in translations])
