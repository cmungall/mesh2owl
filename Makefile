all: mesh-obo.obo

RQUERY = robot query --tdb true

mesh.nt.gz: 
	wget ftp://nlmpubs.nlm.nih.gov/online/mesh/mesh.nt.gz

slim.nt: mesh.nt.gz
	gzip -dc $< | ./fix-nt.pl > $@

slim.rdf: slim.nt
	riot --out=RDFXML $< > $@.tmp && mv $@.tmp $@


Qs = label subclassof syns

gen-%.ttl: slim.rdf construct-%.sparql 
	$(RQUERY) -i $< --construct construct-$*.sparql $@.tmp -f ttl && mv $@.tmp $@
.PRECIOUS: gen-%.ttl

mesh-obo.owl: $(patsubst %, gen-%.ttl, $(Qs))
	owltools $^ --merge-support-ontologies --set-ontology-id http://purl.obolibrary.org/obo/mesh.owl -o $@
.PRECIOUS: mesh-obo.owl

lc-syns.owl: mesh-obo.owl
	$(RQUERY) -i $< --construct construct-shadow-lc-syns.sparql $@.tmp -f ttl && mv $@.tmp $@


mesh-obo.obo: mesh-obo.owl lc-syns.owl
	owltools $^ --merge-support-ontologies -o -f obo --no-check $@.tmp && perl -npe 's@http://id.nlm.nih.gov/mesh/@MESH:@g' $@.tmp > $@

#	robot convert -i $< -o $@
%.json: %.owl
	owltools $< -o -f json $@

# download from https://bioportal.bioontology.org/ontologies/MESH
#mesh.owl: MESH.ttl
#	replace-props.pl $< > $@

## DOCKER

# Building docker image
VERSION = "v0.0.1" 
IM=cmungall/build-mesh

build:
	@docker build -t $(IM):$(VERSION) . \
	&& docker tag $(IM):$(VERSION) $(IM):latest

run:
	docker run --rm -ti --name $(IM) osk

publish: build
	@docker push $(IM):$(VERSION) \
	&& docker push $(IM):latest
