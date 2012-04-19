echo "Removing data, names dir..."
rm -rf /usr/local/apache2/htdocs/modperl/gdb/jbdata/data

echo "Generating annotation..."
/usr/local/apache2/htdocs/web/jbrowse-1.2.1/bin/prepare-refseqs.pl --fasta /usr/local/apache2/htdocs/modperl/gdb/jbdata/annot/MG1655.fasta
/usr/local/apache2/htdocs/web/jbrowse-1.2.1/bin/prepare-refseqs.pl --fasta /usr/local/apache2/htdocs/modperl/gdb/jbdata/annot/EDL933.fasta
/usr/local/apache2/htdocs/web/jbrowse-1.2.1/bin/prepare-refseqs.pl --fasta /usr/local/apache2/htdocs/modperl/gdb/jbdata/annot/Sakai.fasta
/usr/local/apache2/htdocs/web/jbrowse-1.2.1/bin/prepare-refseqs.pl --fasta /usr/local/apache2/htdocs/modperl/gdb/jbdata/annot/CFT073.fasta
/usr/local/apache2/htdocs/web/jbrowse-1.2.1/bin/prepare-refseqs.pl --fasta /usr/local/apache2/htdocs/modperl/gdb/jbdata/annot/UTI89.fasta

/usr/local/apache2/htdocs/web/jbrowse-1.2.1/bin/biodb-to-json.pl --conf /usr/local/apache2/htdocs/modperl/gdb/jbdata/annot/genome.json

/usr/local/apache2/htdocs/web/jbrowse-1.2.1/bin/generate-names.pl -v 
