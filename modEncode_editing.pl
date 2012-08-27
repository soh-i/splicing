#!/usr/bin/evn perl

use strict;
use warnings;

use Data::Dumper;

my $infile = '/home/soh.i/melanogaster/mod_Editing.list';

open my $fh, '<', $infile || die "Cant load $infile: $!";
my $data = {};

while ( my $line = <$fh> ) {
    next if $line =~ m/Gene/;
    
    my @t = split/\t/, $line;
    
    my $gene  = $t[0];
    my $chr   = $t[1];
    my $pos   = $t[2];
    my $type  = $t[3];
    my $known = $t[5];
    
    if ( defined $gene && $gene && $pos =~ m/^[0-9]+$/ ) {
        my $primary_key = "$gene:$pos";
        
        # Chromosome
        if ( defined $chr ) {
            $data->{$primary_key}->{Chr} = $chr;
        }
        else {
            die "Error: undefined chr: $!";
        }
        
        # Gene name
        if ( $gene && defined $gene ) {
            $data->{$primary_key}->{GeneName} = $gene;
            #print $gene; <STDIN>;
        }
        else {
            die "Error: invalid gene name\n";
        }
        
        # Position
        if ( $pos =~ m/^[0-9]+$/ ) {
            $data->{$primary_key}->{Position} = $pos;
        }
        else {
            die "Error: invalid description of editing position\n";
        }

        # Substitution type
        if ( $type && defined $type ) {
            $data->{$primary_key}->{Type} = $type;
        }
        else {
            die "Error: undefined substitution type: $!";
        }
        
        # Known or Unknown
        if ( $known =~ m/[A-Z]+/ ) {
            $data->{$primary_key}->{Known} = $known;
        }
    
        elsif ( $known =~ m/\s+/ ) {
            my $unknown = "-";
            $data->{$primary_key}->{Known} = $unknown;
        }
        else {
            die "Error: undefined un/known\n";
        }
    }
}

my $ref_file = '/home/soh.i/melanogaster/splicing/AS_mergerd';
open my $fh_2, '<', $ref_file || die;

while ( my $ref = <$fh_2> ) {
    next if $ref =~ /\#/;
    
    my @t = split/\t+/, $ref;
    
    my $ref_gene = $t[2] if defined $t[2];
    my $ref_chr;
    my $ref_pos;
    
    foreach my $key ( keys  %{ $data } ) {
        
        if ( defined $data->{$key}->{GeneName}
             && defined $ref_gene
             && $data->{$key}->{GeneName} eq $ref_gene ) {
            
            $data->{$key}->{Edit} = "Edit";
            unless  ( $ref =~ m/Constitutive\sexon/ ) {
                $data->{$key}->{AS} = 'Editing site found in AS exon';
            }   
            
            #print Dumper $data;
            #print $data->{$key}->{GeneName}. "\t";
            #print $data->{$key}->{Chr}. "\t";
            #print $data->{$key}->{Type}. "\t";
            #print $data->{$key}->{Known}. "\t";
            #print $ref_gene. "\n";
                    
            }
        
    }
}


my $count = 0;
foreach my $key ( keys %{ $data } ) {
    if ( $data->{$key}->{Edit} ) {
        $count++;
        print $data->{$key}->{AS}."\n";
        print $data->{$key}->{Type}."\n";
        print $data->{$key}->{Chr}."\n";
        print $data->{$key}->{Position}."\n";
        print $data->{$key}->{GeneName}."\n";
        print "####\n";
    }
    #print "#\n";
}

print "Identified editing sites in AS exon is $count found". "\n";


__END__
        
        #Expression
        #push @{ $data->{$entry}->{RNA_Seq}->{em0_2hr}->{FPKM} }, $t[6];
        #push @{ $data->{$entry}->{RNA_Seq}->{em0_2hr}->{Edit} }, $t[7];
        #push @{ $data->{$entry}->{RNA_Seq}->{em4hr}->{FPKM} }, $t[8];
        #push @{ $data->{$entry}->{RNA_Seq}->{em4hr}->{Edit} }, $t[9];
    #}
    #else {
    #    die "Error: undefined gene or position at $line: $!";
    #}
}
    


