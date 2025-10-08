(: Script XQuery para extraer todos los hechos de un archivo XBRL y exportarlos a CSV, con manejo de errores corregido :)
declare namespace xbrli = "http://www.xbrl.org/2003/instance";
declare namespace ifrs-full = "https://xbrl.ifrs.org/taxonomy/2022-03-24/ifrs-full";
declare namespace co-sspd-ef-Grupo1 = "http://www.superservicios.gov.co/xbrl/niif/ef/core/2024-12-31";
declare namespace xbrldi = "http://xbrl.org/2006/xbrldi";
import module namespace file = "http://expath.org/ns/file";
import module namespace http = "http://expath.org/ns/http-client";

(: Ruta del archivo de salida, más corta y accesible :)
let $output-path := "C:\Users\IPHIX\Documents\Elementos.csv"

(: Encabezados del CSV :)
let $headers := '"Fact ID","Concept","Value","Period","Unit","Decimals","Entity"'

(: Extraer todos los hechos del XBRL (elementos con atributo contextRef) :)
let $facts := try {
  /xbrli:xbrl/*[@contextRef]
} catch * {
  error(QName("http://example.org/errors", "ERR01"), "Error al analizar el documento XBRL: " || $err:description)
}

let $rows := for $fact at $pos in $facts
  let $fact-id := concat('f-', $pos)
  let $concept := local-name($fact)
  let $value := normalize-space(if ($fact/text()) then $fact/text() else '')
  let $context-ref := $fact/@contextRef
  let $context := /xbrli:xbrl/xbrli:context[@id = $context-ref]
  let $period := 
    let $instant := $context/xbrli:period/xbrli:instant
    let $start-date := $context/xbrli:period/xbrli:startDate
    let $end-date := $context/xbrli:period/xbrli:endDate
    return
      if ($instant) then $instant
      else if ($start-date and $end-date) then concat($start-date, '/', $end-date)
      else 'N/A'
  let $unit-ref := $fact/@unitRef
  let $unit := 
    if ($unit-ref) then /xbrli:xbrl/xbrli:unit[@id = $unit-ref]/xbrli:measure
    else 'N/A'
  let $decimals := 
    if ($fact/@decimals) then $fact/@decimals
    else 'N/A'
  let $entity := 
    if ($context/xbrli:entity/xbrli:identifier) then $context/xbrli:entity/xbrli:identifier
    else 'N/A'
  return
    concat(
      '"', $fact-id, '",',
      '"', $concept, '",',
      '"', replace($value, '"', '""'), '",', (: Escapar comillas dobles para CSV :)
      '"', $period, '",',
      '"', $unit, '",',
      '"', $decimals, '",',
      '"', $entity, '"'
    )

(: Combinar encabezados y filas, asegurando formato CSV correcto :)
let $csv-content := string-join(($headers, $rows), '&#10;')

(: Crear directorio y escribir en la ruta especificada con manejo de errores :)
return try {
  file:create-dir("C:\Users\IPHIX\Documents"),
  file:write($output-path, $csv-content),
  "CSV generado exitosamente en " || $output-path
} catch * {
  error(QName("http://example.org/errors", "ERR02"), "Error al escribir el CSV en " || $output-path || ": " || $err:description)
}