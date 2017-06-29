slim.nt: mesh.nt.gz
	gzip -dc $< | ./fix-nt.pl > $@


mesh.nt.gz: 
	wget ftp://nlmpubs.nlm.nih.gov/online/mesh/mesh.nt.gz

gen-%.ttl: slim.nt construct-%.sparql 
	robot query -i $< --construct construct-$*.sparql $@.tmp -f ttl && mv $@.tmp $@


# download from https://bioportal.bioontology.org/ontologies/MESH
#mesh.owl: MESH.ttl
#	replace-props.pl $< > $@
