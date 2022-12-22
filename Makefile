# main target
# (this builds owl as a side-effect)
all: mesh-obo.obo

# alias for robot sparql queries;
# we use TSB for speed
# (you are expected to manage the cache yourself)
RQUERY = robot query --tdb true

# Step 1: download mesh
mesh.nt.gz: 
	wget ftp://nlmpubs.nlm.nih.gov/online/mesh/mesh.nt.gz

# Step 2: very hacky filtering process
# This may remove annotations you care about!
# TODO: replace this with a SPARQL query
slim.nt: mesh.nt.gz
	gzip -dc $< | ./fix-nt.pl > $@

slim.rdf: slim.nt
	riot --out=RDFXML $< > $@.tmp && mv $@.tmp $@

# Step 3: build per-axiom/annotation type files
# each of these uses a custom SPARQL to extract from the raw triples
Qs = label subclassof syns

gen-%.ttl: slim.rdf construct-%.sparql 
	$(RQUERY) -i $< --construct construct-$*.sparql $@.tmp -f ttl && mv $@.tmp $@
.PRECIOUS: gen-%.ttl

# Step 4: merge per-axiom files
# TODO: switch from owltools to robot
mesh-obo.owl: $(patsubst %, gen-%.ttl, $(Qs))
	owltools $^ --merge-support-ontologies --set-ontology-id http://purl.obolibrary.org/obo/mesh.owl -o $@
.PRECIOUS: mesh-obo.owl

# Extra step: add lowercase synonyms
lc-syns.owl: mesh-obo.owl
	$(RQUERY) -i $< --construct construct-shadow-lc-syns.sparql $@.tmp -f ttl && mv $@.tmp $@

# Step 5: make obo format file
# this has hacky step to ensure URIs->OBO IDs
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
