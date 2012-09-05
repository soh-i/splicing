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
    elsif ( $cmd =~ m/^-{2}run$/ ) {
        say "Running..."; #Running program
        sleep(1);
    }
    else {
        say "Input your \'$cmd\' is invalid commandline options!\n";
        say help();
        exit(1);
    }
    
}
else {
    say help();
    exit(1);
}

### INPUT FILES
my $editing_list   = '/home/soh.i/melanogaster/DARNED_dm3.txt';
my $annotation_gtf = '/home/soh.i/melanogaster/Ensembl.genes.gtf';

# Loading DARNED file
open my $list_fh, '<', $editing_list || die $!;
my $list = {};

while ( my $entry = <$list_fh> ) {
    next if $entry =~ m/^chrom\s+coordinate/;
    chomp $entry;
    
    # Parsing DARNED entries
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
    
    my $darned_primary = q//;
    
    if ( is_number($coordinate) == 1 && is_defined($chrom) == 1 ) {
        Readonly $darned_primary => "$chrom-$coordinate";
        
        $list->{$darned_primary}->{coordinate} = $coordinate;
        $list->{$darned_primary}->{chrom}      = $chrom;
        $list->{$darned_primary}->{strand}     = $strand   if is_strand($strand)    == 1;
        $list->{$darned_primary}->{inchr}      = $inchr    if is_defined($inchr)    == 1;
        $list->{$darned_primary}->{inrna}      = $inrna    if is_defined($inrna)    == 1;
        $list->{$darned_primary}->{gene}       = $gene     if is_defined($gene)     == 1;
        $list->{$darned_primary}->{seqReg}     = $seqReg   if is_defined($seqReg)   == 1;
        $list->{$darned_primary}->{exReg}      = $exReg    if is_defined($exReg)    == 1;
        $list->{$darned_primary}->{pubmed}     = $PubmedID if is_defined($PubmedID) == 1;
    }
    else {
        die "coordinate and/or chrom is invalid line at No. $.";
    }
}
close $list_fh;

#print Dumper $list;

# Loading dm3 gtf file
open my $anno_fh, '<', $annotation_gtf || die $!;
my $gtf = {};

while ( my $line = <$anno_fh> ) {
    
    next if $line =~ /#+/;
    next if $line =~ /CDS/;
    
    # Parsing each column
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
    
    # Parsing attribute column
    my @atr = split /\;/, $attribute;
    (my $gene_id         = $atr[0]) =~ s/gene_id|["\s]+//g;
    (my $transcript_id   = $atr[1]) =~ s/transcript_id|["\s]+//g;
    (my $exon_number     = $atr[2]) =~ s/exon_number|["\s]+//g;
    (my $gene_name       = $atr[3]) =~ s/gene_name|["\s]+//g;
    (my $p_id            = $atr[4]) =~ s/p_id|["\s]+//g;
    (my $seqedit         = $atr[5]) =~ s/seqedit|["\s]+//g;
    (my $transcript_name = $atr[6]) =~ s/transcript_name|["\s]+//g;
    (my $tss_id          = $atr[7]) =~ s/tss_id|["\s]+//g; #Contain bug

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
    
    if ( is_defined($gtf_primary) == 1 ) {
        
        if ( is_defined($chromosome) == 1 ) {
            $gtf->{$gtf_primary}->{Chromosome} = $chromosome;
        }
        elsif ( is_defined($chromosome) == 0 ) {
            die "Error: Chromosome is not defined at No. $.";
        }
        if ( is_defined($feature) == 1 ) {
            $gtf->{$gtf_primary}->{Feature} = $feature;
        }
        elsif ( is_defined($feature) == 0 ) {
            die "Error: Feature is not defined at No. $.";
        }
        if ( is_number($start) == 1 ) {
            $gtf->{$gtf_primary}->{Start} = $start;
        }
        elsif ( is_number($start) == 0 ) {
            die "Error: Start is not numetrically at No. $.";
        }
        if ( is_number($end) == 1 ) {
            $gtf->{$gtf_primary}->{End} = $end;
        }
        elsif ( is_number($end) == 0 ) {
            die "Error: End is not numetrically at No. $.";
        }
        if ( is_strand($strand) == 1 ) {
            $gtf->{$gtf_primary}->{Strand} = $strand;
        }
        elsif ( is_strand($strand) == 0 ) {
            die "Error: Strand is an correctly at No. $.";
        }
        if ( defined $frame ) { #is_defined is not work fine
            $gtf->{$gtf_primary}->{Frame} = $frame;
        }
        else {
            say $line;
            die "Error: Frame is not defined at No. $.";
        }
        
        if ( is_defined($attribute) == 1 ) {
            $gtf->{$gtf_primary}->{Attribute}->{GeneID}       = $gene_id       if is_defined($gene_id)       == 1;
            $gtf->{$gtf_primary}->{Attribute}->{ExonNumber}   = $exon_number   if is_number($exon_number)    == 1;
            $gtf->{$gtf_primary}->{Attribute}->{GeneName}     = $gene_name     if is_defined($gene_name)     == 1;
            $gtf->{$gtf_primary}->{Attribute}->{ProteinID}    = $p_id          if is_defined($p_id)          == 1;
            $gtf->{$gtf_primary}->{Attribute}->{TranscriptID} = $transcript_id if is_defined($transcript_id) == 1;
            $gtf->{$gtf_primary}->{Attribute}->{TSSID}        = $tss_id        if is_defined($tss_id)        == 1;
        }
        elsif ( is_defined($attribute) == 0 ) {
            die "Error: Attribute column is not defined";
        }
    }
}
close $anno_fh;

say Dumper $gtf;


### Merging files
foreach my $gtf ( keys %{ $gtf } ) {
    foreach my $editing ( keys %{ $list } ) {
        
    }
}


### HELP MASSAGES
sub help {
    my $msg = <<EOF
###
### This script is used for finding onto RNA editing site in alternative 3' splice site
###

    * Annotation file  = \$annotation_gtf
    * RNA editing site = \$editing_list  #Drived from DAtabase of RNa EDiting in humans

Usage:
       perl $0 --run #Run, output is std

Options: 
       perl $0 --help | -h #Show help messages

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

