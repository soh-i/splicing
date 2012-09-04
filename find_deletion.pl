#!/usr/bin/env perl

use strict;
use warnings;
use 5.12.4;

use Readonly;
use Data::Dumper;

### COMMAND LINE
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

# Loading DARNED file
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

#print Dumper $list;

# Loading dm3 gtf file
open my $anno_fh, '<', $annotation_gtf || die;
my $gtf = {};

while ( my $line = <$anno_fh> ) {
    
    next if $line =~ /#+/;
    next if !$line =~ /exon/;
    
    my @t = split /\t/, $line;
    my $chromosome = $t[0];
    my $source     = $t[1];
    my $feature    = $t[2];
    my $start      = $t[3];
    my $end        = $t[4];
    my $score      = $t[5];
    my $strand     = $t[6];
    my $frame      = $t[7];
    my $attribute  = $t[8];
    
    my @atr = split /\;/, $attribute;
    (my $gene_id         = $atr[0]) =~ s/["]+//g;
    (my $transcript_id   = $atr[1]) =~ s/["\s]+//g;
    (my $exon_number     = $atr[2]) =~ s/["\s]+//g;
    (my $gene_name       = $atr[3]) =~ s/["\s]+//g;
    (my $p_id            = $atr[4]) =~ s/["\s]+//g;
    (my $seqedit         = $atr[5]) =~ s/["\s]+//g;
    (my $transcript_name = $atr[6]) =~ s/["\s]+//g;
    (my $tss_id          = $atr[7]) =~ s/["\s]+//g;

=pod    
    say $gene_id;
    say $transcript_id;
    say $exon_number;
    say $p_id;
    say $seqedit;
    say $transcript_name;
    say $tss_id;
    <STDIN>;
=cut

    my $gtf_primary = q//;
    Readonly $gtf_primary => "$start-$end-$transcript_id-$exon_number";
    die $gtf_primary;
}
close $anno_fh;


foreach my $gtf ( keys %{ $gtf } ) {
    foreach my $editing ( keys %{ $list } ) {
        
    }
}


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

