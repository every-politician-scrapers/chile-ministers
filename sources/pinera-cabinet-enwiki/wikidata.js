const fs = require('fs');
let rawmeta = fs.readFileSync('meta.json');
let meta = JSON.parse(rawmeta);

module.exports = function () {
  return `SELECT DISTINCT (STRAFTER(STR(?item), STR(wd:)) AS ?wdid)
               ?name ?wdLabel ?source ?sourceDate
               (STRAFTER(STR(?positionItem), STR(wd:)) AS ?pid) ?position
               ?startDate ?endDate
               (STRAFTER(STR(?held), '/statement/') AS ?psid)
        WHERE {
          # Positions currently in the cabinet
          ?positionItem wdt:P279 wd:Q3304818 .

          # Who currently holds those positions
          ?item wdt:P31 wd:Q5 ; p:P39 ?held .
          ?held ps:P39 ?positionItem ; pq:P580 ?startDate .
          FILTER NOT EXISTS { ?held wikibase:rank wikibase:DeprecatedRank }
          OPTIONAL { ?held pq:P582 ?endDate }
          FILTER (?endDate > "${meta.cabinet.start}"^^xsd:dateTime)
          FILTER (?startDate < "${meta.cabinet.end}"^^xsd:dateTime)

          OPTIONAL {
            ?held prov:wasDerivedFrom ?ref .
            ?ref pr:P4656 ?source FILTER CONTAINS(STR(?source), 'en.wikipedia.org') .

            OPTIONAL { ?ref pr:P1810 ?sourceName }
            OPTIONAL { ?ref pr:P1932 ?statedName }
            OPTIONAL { ?ref pr:P813  ?sourceDate }
          }

          OPTIONAL { ?item rdfs:label ?wdLabel FILTER(LANG(?wdLabel) = "en") }
          BIND(COALESCE(?sourceName, ?wdLabel) AS ?name)

          OPTIONAL { ?positionItem wdt:P1705  ?nativeLabel   FILTER(LANG(?nativeLabel)   = "en") }
          OPTIONAL { ?positionItem rdfs:label ?positionLabel FILTER(LANG(?positionLabel) = "en") }
          BIND(COALESCE(?statedName, ?nativeLabel, ?positionLabel) AS ?position)
        }
        # ${new Date().toISOString()}
        ORDER BY STR(?name) STR(?position) ?began ?wdid ?sourceDate`
}
