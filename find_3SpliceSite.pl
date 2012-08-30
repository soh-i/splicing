#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

#my $gff_file = '/home/soh.i/melanogaster/Nascent-Seq/20120309UCSC.gene.gtf' || die;
my $gff_file = shift || die;

open my $fh, '<', $gff_file || die "Cant load $gff_file: $!";

my $gff = {};

while ( my $entry = <$fh> ) {
    my @t = split /\t/, $entry;
    
    my $chromosome = $t[0];
    my $source     = $t[1];
    my $feature    = $t[2];
    my $start      = $t[3];
    my $end        = $t[4];
    my $score      = $t[5];
    my $strand     = $t[6];
    my $frame      = $t[7];
    my $attribute  = $t[8];
    
    unless ( $feature =~ m/CDS/ ) {
    
        my $primary_key = q//;
        
        if ( $start =~ m/^[0-9]+$/ && $end =~ m/^[0-9]+$/ ) {
            
            $primary_key = $feature.$start.$end;
            
            my @atr = split /\;/, $attribute;
            my $gene_id    = $atr[0];
            my $tr_id      = $atr[1];
            my $gene_name  = $atr[2];
            my $protein_id = $atr[3];
            my $tss_id     = $atr[4];
            
            if ( $gene_id ) {
                
                $gene_id =~ s/^gene_id\s+//;
                #$tr_id =~ s/\s{1}transcript_id\s+//;
                #$exon_id =~ s/\s{1}exon_id\s+//;
                
                $gene_id =~ s/"//g;
                #$tr_id =~ s/"//g;
                #$exon_id =~ s/"//g;
                #chomp $exon_id;
                
                $chromosome =~ s/chr// if $chromosome =~ m/chr\d/;
                
                $gff->{$primary_key}->{Chromosome} = $chromosome;
                $gff->{$primary_key}->{Gene}       = $gene_id;
                #$gff->{$primary_key}->{Transcript} = $tr_id;
                #$gff->{$primary_key}->{Exon}       = $exon_id;
                $gff->{$primary_key}->{Feature}    = $feature;
                $gff->{$primary_key}->{Start}      = $start;
                $gff->{$primary_key}->{End}        = $end;
            }
        }
    }
}

close $fh;

#print Dumper $gff;


my $infile = '/home/soh.i/melanogaster/mod_Editing.list';

open my $m_fh, '<', $infile || die "Cant load $infile: $!";
my $mod = {};

while ( my $line = <$m_fh> ) {
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
            $mod->{$primary_key}->{Chr} = $chr;
        }
        else {
            die "Error: undefined chr: $!";
        }
        
        # Gene name
        if ( $gene && defined $gene ) {
            $mod->{$primary_key}->{GeneName} = $gene;
            #print $gene; <STDIN>;
        }
        else {
            die "Error: invalid gene name\n";
        }
        
        # Position
        if ( $pos =~ m/^[0-9]+$/ ) {
            $mod->{$primary_key}->{Position} = $pos;
        }
        else {
            die "Error: invalid description of editing position\n";
        }
        
        # Substitution type
        if ( $type && defined $type ) {
            $mod->{$primary_key}->{Type} = $type;
        }
        else {
            die "Error: undefined substitution type: $!";
        }
        
        # Known or Unknown
        if ( $known =~ m/[A-Z]+/ ) {
            $mod->{$primary_key}->{Known} = $known;
        }
        
        elsif ( $known =~ m/\s+/ ) {
            my $unknown = "-";
            $mod->{$primary_key}->{Known} = $unknown;
        }
        else {
            die "Error: undefined un/known\n";
        }
    }
}
close $m_fh;

#print Dumper $mod;


foreach my $gff_site ( keys %{ $gff } ) {
    foreach my $mod_site ( keys %{ $mod } ) {
        #die $mod->{$mod_site}->{Chr};
        
        if( defined $gff->{$gff_site}->{Chromosome} 
            && defined $mod->{$mod_site}->{Chr} ) {
            
            #if ( $gff->{$gff_site}->{Chromosome}  eq $mod->{$mod_site}->{Chr}
            #     &&
            #     $gff->{$gff_site}->{Gene} eq $mod->{$mod_site}->{GeneName} ) {
            if ( $gff->{$gff_site}->{Chromosome} eq $mod->{$mod_site}->{Chr} ) {
                
                #Find Editing site in 3' splice site
                if ( $gff->{$gff_site}->{End} == $mod->{$mod_site}->{Position} ) {
                    print "#End matched\n";
                    print $gff->{$gff_site}->{Gene}. "\t";
                    print $gff->{$gff_site}->{End}. "\t";
                    print $mod->{$mod_site}->{GeneName}. "\t";
                    print $mod->{$mod_site}->{Position}. "\n";
                }
                if ( $gff->{$gff_site}->{Start} == $mod->{$mod_site}->{Position} ) {
                    print "#Start matched\n";
                    print $gff->{$gff_site}->{Gene}. "\t";
                    print $gff->{$gff_site}->{Start}. "\t";
                    print $mod->{$mod_site}->{GeneName}. "\t";
                    print $mod->{$mod_site}->{Position}. "\n";
                }
            }
        }
    }
}
            

