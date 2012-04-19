echo "Removing data, names dir..."
rm -rf /var/www/modperl/gdb/jbdata/data

echo "Generating annotation..."
/var/www/htdocs/jbrowse-1.2.2/bin/prepare-refseqs.pl --fasta /var/www/modperl/gdb/jbdata/annot/MG1655.fasta
/var/www/htdocs/jbrowse-1.2.2/bin/prepare-refseqs.pl --fasta /var/www/modperl/gdb/jbdata/annot/EDL933.fasta
/var/www/htdocs/jbrowse-1.2.2/bin/prepare-refseqs.pl --fasta /var/www/modperl/gdb/jbdata/annot/Sakai.fasta
/var/www/htdocs/jbrowse-1.2.2/bin/prepare-refseqs.pl --fasta /var/www/modperl/gdb/jbdata/annot/CFT073.fasta
/var/www/htdocs/jbrowse-1.2.2/bin/prepare-refseqs.pl --fasta /var/www/modperl/gdb/jbdata/annot/UTI89.fasta

/var/www/htdocs/jbrowse-1.2.2/bin/biodb-to-json.pl --conf /var/www/modperl/gdb/jbdata/annot/genome.json

/var/www/htdocs/jbrowse-1.2.2/bin/generate-names.pl -v 
