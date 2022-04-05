# Jena Fuseki 2 docker image with HDT support

* Docker image: [stain/jena-fuseki](https://hub.docker.com/r/stain/jena-fuseki-hdt/)
* Base images:  [java](https://hub.docker.com/r/_/openjdk):9-jre-slim
* Source: [Dockerfile](https://github.com/stain/jena-docker/blob/master/jena-fuseki-hdt/Dockerfile), [Apache Jena Fuseki](http://jena.apache.org/download/)

This is a [Docker](https://www.docker.com/) image for running
[Apache Jena Fuseki 2](https://jena.apache.org/documentation/fuseki2/),
which is a [SPARQL 1.1](http://www.w3.org/TR/sparql11-overview/) server with a
web interface, backed by the
[Apache Jena TDB](https://jena.apache.org/documentation/tdb/) RDF triple store
extended with support for
[HDT Files](https://github.com/rdfhdt/hdt-java) files.

## License

Different licenses apply to files added by different Docker layers:

* stain/jena-fuseki [Dockerfile](https://github.com/stain/jena-docker/blob/master/jena-fuseki/Dockerfile): [Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
* Apache Jena (`/jena-fuseki` in the image): [Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
  See also: `docker run stain/jena cat /jena/NOTICE`
* OpenJDK (`/usr/lib/jvm/default-jvm/j` in the image): [GPL 2.0 with Classpath exception](http://openjdk.java.net/legal/gplv2+ce.html)
  See also: `docker run stain/jena cat /usr/lib/jvm/default-jvm/jre/LICENSE`
* HDT [Various Licenses](https://github.com/rdfhdt/hdt-java/blob/master/LICENSE)


## Use

This image works the same as the [jena-fuseki](../jena-fuseki) docker image, and
you can see description for general usage.

### Adding an HDT file as a persistent graph

If you'd like to add an HDT file as a persistent read-only graph, then you need
to both load the data, and upload a configuration file for your container.

If you have a persistent disk image `fuseki-data`, then you can copy an HDT file
directly to that image.

``` bash
docker cp example_graph.hdt fuseki-data:/fuseki/databases
```

An alternative would be to create a second volume that holds only the hdt files.
You might want to do this if you'd like to share that volume with other docker
containers.   This is okay, as these files are read-only..

``` bash
cat <<CONFIG >> example_config.ttl
@prefix :      <#> .
@prefix ja:    <http://jena.hpl.hp.com/2005/11/Assembler#> .
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .
@prefix fuseki: <http://jena.apache.org/fuseki#> .
@prefix hdt: <http://www.rdfhdt.org/fuseki#> .

# HDT Classes
hdt:HDTGraph rdfs:subClassOf ja:Graph .

:example_service a fuseki:Service ;
    rdfs:label                      "Example Service" ;
    fuseki:name                     "example" ;
    fuseki:serviceQuery             "query", "sparql" ;
    fuseki:serviceReadGraphStore    "get" ;
    fuseki:dataset                   [ a ja:RDFDataset ;
                                       ja:defaultGraph :example_graph ] ;
    .

:example_graph a hdt:HDTGraph;
    rdfs:label "Example HDT Graph" ;
    hdt:fileName "/fuseki/databases/example_graph.hdt" ;

        # Optional: Keep the HDT and index in memory at all times.
        # Uses more memory but it is potentially faster because avoids IO.
        # hdt:keepInMemory "true" ;
    .
CONFIG;
# Then copy this to your image data
docker cp example_config.ttl fuseki-data:/fuseki/configurations
```

After running `docker restart fuseki` in this case, you will now have a
read-only additional dataset.

### Extended Example

The [example](./example) directory contains a more complete example that shows
how this image can be used, it includes two examples, using docker-compose files
to manage the data and the container.


## Customizing Fuseki configuration

If you need to modify Fuseki's configuration further, you can use the equivalent of:

    docker run --volumes-from fuseki-data -it ubuntu bash

and inspect `/fuseki` with the shell. Remember to restart fuseki afterwards:

    docker restart fuseki
