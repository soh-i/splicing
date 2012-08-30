#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

#loading nascent-seq file
my $infile = '/home/soh.i/melanogaster/Nascent.txt';

open my $fh, '<', $infile || die "Cant load $infile: $!";
my $data = {};

while ( my $line = <$fh> ) {
    next if $line =~ m/^CG\sID/;
    my @t = split/\t/, $line;
    
    my $gene_name = $t[1];
    my $type      = $t[2];
    my $chr       = $t[3];
    my $loci      = $t[4];
    
    $loci =~ s/\"?//g;
    $loci =~ s/\,?//g;
    $chr =~ s/^chr//g;
    
    $data->{$gene_name.$loci}->{Gene} = $gene_name;
    $data->{$gene_name.$loci}->{Type} = $type;
    $data->{$gene_name.$loci}->{Chr}  = $chr;
    $data->{$gene_name.$loci}->{Loci} = $loci;

}
close $fh;

#loading AS reference file
my $as_file = '../flybase_TranscriptEvent.tsv';

open my $as, '<', $as_file || die;
my $ref_data = {};

while ( my $ref = <$as> ) {
    
    next if $ref =~ m/Ensembl\s/;
    my @t = split/\t/, $ref;
    
    my $gene_id        = $t[0];
    my $transcript_id  = $t[1];
    my $exon_id        = $t[2];
    my $chromosome     = $t[3];
    my $event_name     = $t[4];
    my $ExonStart      = $t[5];
    my $ExonEnd        = $t[6];
    
    $ref_data->{$gene_id.$ExonStart}->{Chr} = $chromosome;
    $ref_data->{$gene_id.$ExonStart}->{ExonStart} = $ExonStart;
    $ref_data->{$gene_id.$ExonStart}->{ExonEnd} = $ExonEnd;
  
}
close $as_file;

# Find editing site onto splice site
foreach my $ref_key ( keys %{ $data } ) {
    foreach my $as_key ( keys %{ $ref_data } ) {
        
        if ( $data->{$ref_key}->{Chr} eq $ref_data->{$as_key}->{Chr} ) {
            #print $data->{$ref_key}->{Loci};
            #die $ref_data->{$as_key}->{ExonStart};
            
            if ( $data->{$ref_key}->{Loci} == $ref_data->{$as_key}->{ExonStart}
                 ||
                 $data->{$ref_key}->{Loci} == $ref_data->{$as_key}->{ExonEnd} ) {
                
                print $data->{$ref_key}->{Loci}. "\t";
                print $ref_data->{$as_key}->{ExonStart}. "\t";
                print "\n";
            }
        }
    }
}



