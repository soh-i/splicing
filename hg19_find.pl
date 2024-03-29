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
my $editing_list   = '/home/soh.i/Human/DARNED_hg19.txt';
my $annotation_gtf = '/home/soh.i/Human/Homo_sapiens/Ensembl/GRCh37/Annotation/Genes/genes.gtf';


# Loading DARNED file
open my $list_fh, '<', $editing_list || die $!;
my $darned_data = {};

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
        
        $darned_data->{$darned_primary}->{coordinate} = $coordinate;
        $darned_data->{$darned_primary}->{chrom}      = $chrom;
        $darned_data->{$darned_primary}->{strand}     = $strand   if is_strand($strand)    == 1;
        $darned_data->{$darned_primary}->{inchr}      = $inchr    if is_defined($inchr)    == 1;
        $darned_data->{$darned_primary}->{inrna}      = $inrna    if is_defined($inrna)    == 1;
        $darned_data->{$darned_primary}->{gene}       = $gene     if is_defined($gene)     == 1;
        $darned_data->{$darned_primary}->{seqReg}     = $seqReg   if is_defined($seqReg)   == 1;
        $darned_data->{$darned_primary}->{exReg}      = $exReg    if is_defined($exReg)    == 1;
        $darned_data->{$darned_primary}->{pubmed}     = $PubmedID if is_defined($PubmedID) == 1;
    }
    else {
        die "coordinate and/or chrom is invalid line at No. $.";
    }
}
close $list_fh;

#print Dumper $darned_data;

# Loading dm3 gtf file
open my $anno_fh, '<', $annotation_gtf || die $!;
my $gtf_data = {};

while ( my $line = <$anno_fh> ) {
    
    next if $line =~ /#+/;
    #next if $line =~ /CDS/;
    
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
    (my $gene_biotype    = $atr[3]) =~ s/gene_biotype|["\s]+//g;
    (my $gene_name       = $atr[4]) =~ s/gene_name|["\s]+//g;
    (my $transcript_name = $atr[5]) =~ s/transcript_name|["\s]+//g;
    
    #avoid undefined $tss_id
    my $tss_id = q//;
    eval {
        ($tss_id = $atr[7]) =~ s/tss_id|["\s]+//g if defined $atr[7];
    };
    if ($@) {
        die $line;
    }

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
            $gtf_data->{$gtf_primary}->{Chromosome} = $chromosome;
        }
        elsif ( is_defined($chromosome) == 0 ) {
            die "Error: Chromosome is not defined at No. $.";
        }
        if ( is_defined($feature) == 1 ) {
            $gtf_data->{$gtf_primary}->{Feature} = $feature;
        }
        elsif ( is_defined($feature) == 0 ) {
            die "Error: Feature is not defined at No. $.";
        }
        if ( is_number($start) == 1 ) {
            $gtf_data->{$gtf_primary}->{Start} = $start;
        }
        elsif ( is_number($start) == 0 ) {
            die "Error: Start is not numetrically at No. $.";
        }
        if ( is_number($end) == 1 ) {
            $gtf_data->{$gtf_primary}->{End} = $end;
        }
        elsif ( is_number($end) == 0 ) {
            die "Error: End is not numetrically at No. $.";
        }
        if ( is_strand($strand) == 1 ) {
            $gtf_data->{$gtf_primary}->{Strand} = $strand;
        }
        elsif ( is_strand($strand) == 0 ) {
            die "Error: Strand is an correctly at No. $.";
        }
        if ( defined $frame ) { #is_defined is not work fine
            $gtf_data->{$gtf_primary}->{Frame} = $frame;
        }
        else {
            say $line;
            die "Error: Frame is not defined at No. $.";
        }
        
        # Attribute column
        if ( is_defined($attribute) == 1 ) {
            $gtf_data->{$gtf_primary}->{Attribute}->{GeneID}       = $gene_id       if is_defined($gene_id)       == 1;
            $gtf_data->{$gtf_primary}->{Attribute}->{ExonNumber}   = $exon_number   if is_number($exon_number)    == 1;
            $gtf_data->{$gtf_primary}->{Attribute}->{Biotype}      = $gene_biotype  if is_defined($gene_biotype)  == 1;
            $gtf_data->{$gtf_primary}->{Attribute}->{GeneName}     = $gene_name     if is_defined($gene_name)     == 1;
            $gtf_data->{$gtf_primary}->{Attribute}->{TranscriptID} = $transcript_id if is_defined($transcript_id) == 1;
            $gtf_data->{$gtf_primary}->{Attribute}->{TSSID}        = $tss_id        if is_defined($tss_id)        == 1;
        }
        elsif ( is_defined($attribute) == 0 ) {
            die "Error: Attribute column is not defined";
        }
    }
}
close $anno_fh;

#say Dumper $gtf_data;

### Findling 3' splice site in editing site
foreach my $gtf_key ( keys %{ $gtf_data} ) {
    foreach my $darned_key ( keys %{ $darned_data } ) {
        if ( $gtf_data->{$gtf_key}->{Chromosome} eq $darned_data->{$darned_key}->{chrom} ) {
            
            my $A_of_AG = ($gtf_data->{$gtf_key}->{Start}-2);
            if ( $A_of_AG == $darned_data->{$darned_key}->{coordinate} ) {
                say "Feature:                $gtf_data->{$gtf_key}->{Feature}";
                say "Gene Biotype:           $gtf_data->{$gtf_key}->{Biotype}";
                say "3' splice site pos:     $A_of_AG";
                say "DARNED editing pos:     $darned_data->{$darned_key}->{coordinate}";
                say "Located event(E/I):     $darned_data->{$darned_key}->{seqReg}";
                say "GTF Gene name:          $gtf_data->{$gtf_key}->{Attribute}->{GeneName}";
                say "GTF Gene ID:            $gtf_data->{$gtf_key}->{Attribute}->{GeneID}";
                say "GTF Chromosome:         $gtf_data->{$gtf_key}->{Chromosome}";
                say "GTF transcript ID:      $gtf_data->{$gtf_key}->{Attribute}->{TranscriptID}";
                say "GTF exon number:        $gtf_data->{$gtf_key}->{Attribute}->{ExonNumber}";
                say "Pubmed ID:              $darned_data->{$darned_key}->{pubmed}";
                say "##";
            }
        }
    }
}


### HELP MASSAGES
sub help {
    my $msg = <<EOF
###
### This script is used for finding onto RNA editing site in alternative 3' splice site
### in Human hg19 version.

    * Annotation file  = /home/soh.i/Human/Homo_sapiens/Ensembl/GRCh37/Annotation/Genes/genes.gtf
    * RNA editing site = /home/soh.i/Human/DARNED_hg19.txt (#Drived from DAtabase of RNa EDiting in humans)

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

