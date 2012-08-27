#!/usr/bin/evn perl

use strict;
use warnings;

use Data::Dumper;

my $infile = shift || die "Speficied file!";

open my $fh, '<', $infile || die "Cant load $infile: $!";
my $data = {};

while ( my $line = <$fh> ) {
    next if $line =~ m/Gene/;
    
    my @t = split/\t/, $line;
    
    # Parse gene and position as key of data
    if ( defined $t[0] && defined $t[2] ) {
        my $gene = $t[0];
        my $position = $t[2];
        
        my $entry = "$gene:$position";
                
        # Chromosome
        if ( defined $t[1] ) {
            my $chr  = $t[1];
            $data->{$entry}->{Chr} = $chr;
        }
        else {
            die "Error: undefined chr: $!";
        }

        # Substitution type
        if ( defined $t[3] ) {
            my $type = $t[3];
            $data->{$entry}->{Type} = $type;
        }
        else {
            die "Error: undefined substitution type: $!";
        }
        
        # Known or Unknown
        if ( $t[5] =~ m/[A-Z]+/ ) {
            my $known = $t[5];
            $data->{$entry}->{Known} = $known;
        }
        else {
            my $unknown = $t[5];
            $unknown = "unknown";
            $data->{$entry}->{Known} = $unknown;
        }
        
        #Expression
        push @{ $data->{$entry}->{RNA_Seq}->{em0_2hr}->{FPKM} }, $t[6];
        push @{ $data->{$entry}->{RNA_Seq}->{em0_2hr}->{Edit} }, $t[7];
        push @{ $data->{$entry}->{RNA_Seq}->{em4hr}->{FPKM} }, $t[8];
        push @{ $data->{$entry}->{RNA_Seq}->{em4hr}->{Edit} }, $t[9];
    }
    else {
        die "Error: undefined gene or position at $line: $!";
    }
}



print Dumper $data;
