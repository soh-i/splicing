#!/usr/bin/env perl

use strict;
use warnings;

use 5.12.4;

use Data::Dumper;

my $infile = shift || die help();

my $data = {};

open my $fh, '<', $infile || die;
while ( my $line = <$fh> ) {
    next if $line =~ m/Ensembl/;
    
    my @t = split /\t/, $line;
    
    if ( $t[1] =~ m/^FBtr[0-9]+$/ && $t[0] =~ m/^FBgn[0-9]+$/ ) {
        my $Gene             = $t[0];
        my $Transcript       = $t[1];
        my $GeneName_with_AS = $t[2];
        
        $data->{$Transcript}->{FBgene} = $Gene;
        push @{ $data->{$Transcript}->{Event} }, $GeneName_with_AS;
        
        
        #my $Chromosome = $t[3];
        #my $NameEvent = $t[4];
        #my $Start = $t[5];
        #my $End = $t[6];
        #my $EventName = $t[7];
        
    }
}


print Dumper $data;

sub help {
    
    my $msg = <<EOF;
this script is used for parsing alternative splicing events data from Ensembl BioMart

Usage:
       perl $0 <in.data> 

EOF

    return scalar $msg;
}
