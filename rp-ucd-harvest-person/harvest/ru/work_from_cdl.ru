PREFIX FoR: <http://experts.ucdavis.edu/concept/FoR/>
PREFIX aeq: <http://experts.ucdavis.edu/queries/schema#>
PREFIX afn: <http://jena.apache.org/ARQ/function#>
PREFIX authorship: <http://experts.ucdavis.edu/authorship/>
PREFIX bibo: <http://purl.org/ontology/bibo/>
PREFIX experts: <http://experts.ucdavis.edu/>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX free: <http://experts.ucdavis.edu/concept/free>
PREFIX grant: <http://experts.ucdavis.edu/grant/>
PREFIX harvest_iam: <http://iam.ucdavis.edu/>
PREFIX harvest_oap: <http://oapolicy.universityofcalifornia.edu/>
PREFIX iam: <http://iam.ucdavis.edu/schema#>
PREFIX list: <http://jena.apache.org/ARQ/list#>
PREFIX oap: <http://oapolicy.universityofcalifornia.edu/vocab#>
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX person: <http://experts.ucdavis.edu/person/>
PREFIX private: <http://experts.ucdavis.edu/private/>
PREFIX purl: <http://purl.org/ontology/bibo/>
PREFIX q: <http://experts.ucdavis.edu/queries/>
PREFIX query: <http://experts.ucdavis.edu/schema/queries/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX ucdrp: <http://experts.ucdavis.edu/schema#>
PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>
PREFIX venue: <http://experts.ucdavis.edu/venue/>
PREFIX vivo: <http://vivoweb.org/ontology/core#>
PREFIX work: <http://experts.ucdavis.edu/work/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

insert { graph this_graph:new {
  ?experts_work_id a ?bibo_type;
                   rdfs:label ?title;
                   bibo:status ?vivoStatus;
                   ucdrp:best_source ?source;
                   ucdrp:lastModifiedDateTime ?lastModifiedDateTime;
                   ucdrp:insertionDateTime ?insertionDateTime;
                   ?bibo_predicate ?field_text;
                   ucdrp:pagination_source ?page_source;
                   bibo:pageStart ?begin;
                   bibo:pageEnd ?end;
                   vivo:dateTimeValue ?work_date;
                   vivo:hasPublicationVenue ?journalURI;
                   .

  ?work_date a vivo:DateTimeValue;
             vivo:dateTime ?workDateTime;
             vivo:dateTimePrecision ?dateTimePrecision;
             .

  ?journalURI a bibo:Journal, ucdrp:venue;
                rdfs:label ?journalTitle;
                bibo:issn ?issn;
                bibo:eissn ?eissn;
                vivo:publicationVenueFor ?experts_work_id;
                .

  ?keyword a skos:Concept, ucdrp:concept;
             skos:prefLabel ?term;
             rdfs:label ?term;
             ucdrp:scheme "freetext";
             skos:inScheme free: ;
  .
  ?experts_work_id vivo:hasSubjectArea ?keyword.
  ?keyword vivo:subjectAreaOf ?experts_work_id.


  ?concept a ?type, ucdrp:concept;
             skos:broader ?broader;
             skos:inScheme FoR:;
             skos:prefLabel ?concept_prefLabel;
             rdfs:label ?concept_label;
             .

  ?broader skos:narrower ?concept.

  ?experts_work_id vivo:hasSubjectArea ?conceptURI .
  ?conceptURI vivo:subjectAreaOf ?experts_work_id .

  ?authorship a vivo:Authorship,ucdrp:authorship;
              vivo:rank ?authorRank;
              vivo:relates ?experts_work_id;
              vivo:relates ?authorship_vcard;
              .

  ?authorship_vcard a vcard:Individual;
                    vivo:relatedBy ?vcard;
                    vcard:hasName ?authorship_vcard_name;
                    .

  ?authorship_vcard_name  a vcard:Name;
                          vcard:familyName ?authorLastName;
                          vcard:givenName ?authorFirstName ;
  .

  ?experts_work_id vivo:relatedBy ?authorship.

}}
WHERE {
  VALUES(?oap_type ?bibo_type){
    ("book" bibo:Book)
    ("chapter" bibo:Chapter)
    ("conference" vivo:ConferencePaper)
    ("journal-article" bibo:AcademicArticle)
    ("preprint" ucdrp:PrePrint)
  }
  VALUES(?field_name ?bibo_predicate) {
    ("title" rdfs:label)
    ("abstract" bibo:abstract)
    ("author-url" bibo:uri)
    ("doi" bibo:doi)
    ("isbn-10" bibo:isbn10)
    ("isbn-13" bibo:isbn13)
    ("issue" bibo:issue)
    ("journal" bibo:journal)
    ("number" bibo:number)
    ("publish-url" bibo:uri)
    ("public-url" bibo:uri)
    ("c-eschol-id" bibo:identifier)
    ("volume" bibo:volume)
  }

  bind(this_pub: as ?pub)
  ?pub oap:category "publication".

  {
    select ?pub ?best_record ?native WHERE {
      { select ?pub ?best_record (min(?a_native) as ?native) WHERE {
        ?best_record oap:native ?a_native.
        {
          SELECT ?pub (MIN(?record) AS ?best_record) WHERE {
            VALUES (?sourceNameA ?minPriority) {
              ("verified-manual" 1) ("epmc" 8) ("pubmed" 3)  ("scopus" 104)("wos" 5) ("wos-lite" 6)
              ("crossref" 7)  ("dimensions" 102) ("arxiv" 9)("orcid" 10) ("dblp" 11)  ("cinii-english" 12)
              ("repec" 13)  ("figshare" 14)  ("cinii-japanese" 15) ("manual" 16)  ("dspace" 17) }
            ?pub oap:category "publication" ;
            oap:records/oap:record ?record .
            ?record oap:source-name  ?sourceNameA
            {
              SELECT
              ?pub (MIN(?priority) AS ?minPriority)
              WHERE {
                VALUES (?sourceNameIQ ?priority) {
                  ("verified-manual" 1) ("epmc" 8) ("pubmed" 3)  ("scopus" 104)("wos" 5) ("wos-lite" 6)
                  ("crossref" 7)  ("dimensions" 102) ("arxiv" 9)("orcid" 10) ("dblp" 11)  ("cinii-english" 12)
                  ("repec" 13)  ("figshare" 14)  ("cinii-japanese" 15) ("manual" 16)  ("dspace" 17) }
                ?pub oap:category "publication" ;
                oap:records/oap:record/oap:source-name ?sourceNameIQ
              } GROUP BY ?pub }
          } GROUP BY ?pub }
      } GROUP BY ?pub ?best_record }
      bind(replace(str(?pub),str(harvest_oap:),'') as ?pub_number)
      bind(uri(concat(str(work:),?pub_number)) as ?experts_work_id)
    }
  }
  bind(replace(str(?pub),str(harvest_oap:),'') as ?pub_id)
  bind(uri(concat(str(work:),?pub_id)) as ?experts_work_id)

  # Page source
  { select ?page_source ?begin ?end
    WHERE {
      VALUES (?page_source ?page_priority) {
        ("verified-manual" 1) ("epmc" 2) ("pubmed" 3)  ("scopus" 4)("wos" 5) ("wos-lite" 6)
        ("crossref" 7)  ("dimensions" 8) ("arxiv" 9)("orcid" 10) ("dblp" 11)  ("cinii-english" 12)
        ("repec" 13)  ("figshare" 14)  ("cinii-japanese" 15) ("manual" 16)  ("dspace" 17) }

      ?pub oap:category "publication";
           oap:records/oap:record ?record .
      ?record oap:source-name  ?page_source;
              oap:native/oap:field/oap:pagination [oap:begin-page ?begin; oap:end-page ?end ];
                                                                                       .
      {
        select ?pub (min(?mpriority) as ?page_priority) WHERE {
          VALUES (?msource ?mpriority) {
            ("verified-manual" 1) ("epmc" 2) ("pubmed" 3)  ("scopus" 4)("wos" 5) ("wos-lite" 6)
            ("crossref" 7)  ("dimensions" 8) ("arxiv" 9)("orcid" 10) ("dblp" 11)  ("cinii-english" 12)
            ("repec" 13)  ("figshare" 14)  ("cinii-japanese" 15) ("manual" 16)  ("dspace" 17) }
          ?work oap:category "publication";
                oap:records/oap:record [ oap:source-name  ?msource;
                                         oap:native/oap:field/oap:pagination [] ].
        } group by ?pub
      }
    }
  }

  ?pub oap:type ?oap_type;
       oap:last-modified-when ?lastModifiedWhen;
       .

  BIND(xsd:dateTime(?lastModifiedWhen) AS ?lastModifiedDateTime)
  BIND(NOW() as ?insertionDateTime)

  ?best_record oap:source-name ?source.

  ?native oap:field [ oap:name ?field_name ; oap:text ?field_text ].

  # Authorship
  OPTIONAL {
    ?native oap:field [ oap:name "authors" ; oap:people/oap:person [ list:index(?pos ?elem) ] ] .
    BIND(?pos+1 AS ?authorRank)
    OPTIONAL {
      ?elem oap:last-name ?authorLastName .
    }
    OPTIONAL {
      ?elem oap:first-names ?authorFirstName .
    }
  }
  BIND(uri(concat(replace(str(?experts_work_id),str(work:),str(authorship:)),"-",str(?authorRank))) as ?authorship)
  BIND(uri(concat(str(?authorship),"#vcard")) as ?authorship_vcard)
  BIND(uri(concat(str(?authorship_vcard),"-name")) as ?authorship_vcard_name)


  # Journal Information
  OPTIONAL {
    ?native oap:field [ oap:name "journal" ; oap:text ?journalTitle ].
    OPTIONAL {
      ?native oap:field [ oap:name "eissn" ; oap:text ?eissn ].
    }
    OPTIONAL {
      ?native oap:field [ oap:name "issn" ; oap:text ?issn ].
    }
    BIND(REPLACE(REPLACE(LCASE(STR(?journalTitle)), '[^\\w\\d]','-'), '-{2,}' ,'-') AS ?journalIdText)
    BIND(URI(CONCAT(str(venue:), COALESCE(CONCAT("issn:", ?issn), CONCAT("eissn:", ?eissn), CONCAT("journal:", ?journalIdText)))) AS ?journalURI)
  }

  # Keywords ( from every record!)
  OPTIONAL {
    {
      ?pub oap:records/oap:record/oap:native/oap:field  [ oap:name "keywords" ; oap:keywords/oap:keyword ?term ]
      #        ?native oap:field  [ oap:name "keywords" ; oap:keywords/oap:keyword ?term ]
      FILTER(!ISBLANK(?term))
      #          bind ("free" as ?scheme)
    }
    UNION
    {
      ?pub oap:records/oap:record/oap:native/oap:field  [ oap:name "keywords" ; oap:keywords/oap:keyword/oap:field-value ?term ]
      #        ?native oap:field  [ oap:name "keywords" ; oap:keywords/oap:keyword/oap:field-value ?term ]
      FILTER(!ISBLANK(?term))
      #          bind ("free" as ?scheme)
    }
    UNION
    {
      ?pub oap:all-labels/oap:keywords/oap:keyword [ oap:field-value ?term ; oap:scheme ?scheme ] .
    }
    bind(IRI(concat(str(free:),md5(lcase(?term)))) as ?keyword)
  }

  # FoR
  OPTIONAL {
    ?pub oap:all-labels/oap:keywords/oap:keyword [ oap:field-value ?con ; oap:scheme 'for' ] .
    BIND(URI(CONCAT(str(FoR:), REPLACE(?con," .*",""))) AS ?_concept)

    graph FoR: {
      ?_concept skos:inScheme FoR:;
                skos:broader* ?concept;
                .
      ?concept a ?type;
               rdfs:label ?concept_label;
               skos:broader ?broader;
               skos:prefLabel ?concept_prefLabel;
               .
    }
  }


  # Publication Date
  OPTIONAL {
    {
      ?native oap:field [ oap:name "publication-date" ; oap:date ?wd_date ].
    }
    UNION
    {
      ?native oap:field [ oap:name "online-publication-date" ; oap:date ?wd_online ].
    }
    bind(coalesce(?wd_date,?wd_online) as ?workDate)
    ?workDate oap:year ?workDateYear
    BIND(vivo:yearPrecision AS ?yearPrecision)
    OPTIONAL {
      ?workDate oap:month ?workDateMonthRaw
      BIND(IF(xsd:integer(?workDateMonthRaw)<10, #>
              CONCAT("0", ?workDateMonthRaw), ?workDateMonthRaw) AS ?workDateMonth)
      BIND(vivo:yearMonthPrecision AS ?yearMonthPrecision)
      OPTIONAL {
        ?workDate oap:day ?workDateDayRaw
        BIND(IF(xsd:integer(?workDateDayRaw) < 10, #>
                CONCAT("0", ?workDateDayRaw), ?workDateDayRaw) AS ?workDateDay)
        BIND(vivo:yearMonthDayPrecision AS ?yearMonthDayPrecision)
      }
    }
    BIND(xsd:dateTime(CONCAT(?workDateYear, "-", COALESCE(?workDateMonth, "01"), "-", COALESCE(?workDateDay, "01"), "T00:00:00")) AS ?workDateTime)
    BIND(COALESCE(?yearMonthDayPrecision, ?yearMonthPrecision, ?yearPrecision) AS ?dateTimePrecision)
    bind("#date" as ?date_part)
  }
  bind(uri(concat(str(?experts_work_id),?date_part)) as ?work_date)

  OPTIONAL {
    VALUES (?status ?vivoStatus) { ( "Published" bibo:published ) ( "Published online" bibo:published ) ( "Accepted" bibo:accepted ) }
    ?best_native oap:field [ oap:name "publication-status" ; oap:text ?status ]
  }
}
