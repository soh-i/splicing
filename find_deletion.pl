#!/usr/bin/env perl

use strict;
use warnings;
use 5.12.4;

use Readonly;
use Data::Dumper;

if ( scalar @ARGV != 0 ) {
    my $cmd = join ",", @ARGV;
    if ( $cmd =~ m/^-{2}help$/ || $cmd =~ m/^\-{1}h$/ ) {
        say help();
        exit(1);
    }
    else {
        say "Input your \'$cmd\' is invalid commandline options!\n";
        say help();
        exit(1);
    }
}

### INPUT FILES
my $editing_list = '/home/soh.i/melanogaster/DARNED_dm3.txt';
my $annotation_gtf = '/home/soh.i/melanogaster/Ensembl.genes.gtf';

# Loading 
open my $list_fh, '<', $editing_list || die;
my $list = {};
while ( my $entry = <$list_fh> ) {
    next if $entry =~ m/^chrom\s+coordinate/;
    chomp $entry;
    
    my @t = split/\t+/, $entry;
    my $chrom      = $t[0];
    my $coordinate = $t[1];
    my $strand     = $t[2];
    my $inchr      = $t[3];
    my $inrna      = $t[4];
    my $gene       = $t[5];
    my $seqReg     = $t[6];
    my $exReg      = $t[7];
    my $PubmedID   = $t[8];
    
    my $primary = q//;
    
    if ( is_number($coordinate) == 1 && is_defined($chrom) == 1 ) {
        Readonly $primary => "$chrom-$coordinate";
        
        $list->{$primary}->{coordinate} = $coordinate;
        $list->{$primary}->{chrom}      = $chrom;
        $list->{$primary}->{strand}     = $strand   if is_strand($strand)    == 1;
        $list->{$primary}->{inchr}      = $inchr    if is_defined($inchr)    == 1;
        $list->{$primary}->{inrna}      = $inrna    if is_defined($inrna)    == 1;
        $list->{$primary}->{gene}       = $gene     if is_defined($gene)     == 1;
        $list->{$primary}->{seqReg}     = $seqReg   if is_defined($seqReg)   == 1;
        $list->{$primary}->{exReg}      = $exReg    if is_defined($exReg)    == 1;
        $list->{$primary}->{pubmed}     = $PubmedID if is_defined($PubmedID) == 1;
    }
    else {
        die "coordinate and/or chrom is invalid in $entry";
    }
}
close $list_fh;

print Dumper $list;





open my $anno_fh, '<', $annotation_gtf || die;
my $gtf = {};
while ( my $line = <$anno_fh> ) {
}

close $anno_fh;


### HELP MASSAGES
sub help {
    my $msg = <<EOF
this script is used for finding onto RNA editing site in alternative 3' splice site
    Annotation file = $annotation_gtf
    RNA editing site = $editing_list

Usage:
       perl $0

EOF
}


#### FORMAT VALIDATOR ####
sub is_number {
    my $ex_int = shift;
    
    if ( $ex_int =~ m/^[0-9]+$/ ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_char {
    my $ex_char = shift;
    
    if ( $ex_char =~ m/^[A-Za-z]+$/ ) {
        return scalar 1;
    }
    else {
        return scalar 0;
    }
}

sub is_defined {
    my $ex_string = shift;
    
    if ( defined $ex_string && $ex_string ) {
        return scalar 1;
    }
    else {
        return scalar 0;
    }
}

sub is_strand {
    my $ex_strand = shift;
    
    if ( $ex_strand =~ m/^[-+]$/ ) {
        return scalar 1;
    }
    else {
        return scalar 0;
    }
}

