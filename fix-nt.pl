#!/usr/bin/perl
while(<>) {
    next unless m@^<http://id.nlm.nih.gov/mesh/[CDTM]\w{6,7}>@;
    s@http://id.nlm.nih.gov/mesh/vocab#broaderDescriptor@http://www.w3.org/2002/07/owl#subClassOf@;
    if (m@subClassOf|label|comment|preferredConcept|prefLabel|#term@) {
        print;
    }
}
