#!/usr/bin/env perl

use strict;
use warnings;
use 5.12.4;

use Data::Dumper;

# Reference file
my $structures_file = '/home/soh.i/melanogaster/flybase_structures.tsv';
# File that annotation of Alternative splicing 
my $events_file     = '/home/soh.i/melanogaster/flybase_TranscriptEvent.tsv';

# Command line options
if ( scalar @ARGV == 1 ) {
    if ( $ARGV[0] eq "--help" || $ARGV[0] eq "-h" ) {
        print help();
        exit (1);
    }
    else {
        print "####Invalid options!####\n\n";
        print help();
        exit(1);
    }
}

open my $fh_s, '<', $structures_file || die "Cant load $structures_file: $!";
open my $fh_e, '<', $events_file || die "Cant load $events_file: $!";

my $data = {};
my $parsed_error = 0;

##### Parsing flybase_structures file... #####
while ( my $entry = <$fh_s> ) {
    next unless $entry =~ m/^FBgn[0-9]+/;
    
    #Exception: no entry found at FBgn0033087
    next if $entry =~ m/FBgn0033087/;
    
    my @t = split/\t/, $entry;
    
    my $gene_id        = $t[0];
    my $transcript_id  = $t[1];
    my $exon_id        = $t[2];
    my $gene_name      = $t[3];
    my $chromosome     = $t[4];
    my $strand         = $t[5];
    my $gene_start     = $t[6];
    my $gene_end       = $t[7];
    my $fiveUTR_Start  = $t[8];
    my $fiveUTR_End    = $t[9];
    my $threeUTR_Start = $t[10];
    my $threeUTR_End   = $t[11];
    my $ExonStart      = $t[12];
    my $ExonEnd        = $t[13];
    
    #this variable is 'pure' FBtr[0-9]+ ID 
    my $tr_id = $transcript_id;
    
    #$primary is used as primary key of struct
    my $joiner = "-";
    my $primary = $transcript_id.$joiner.$exon_id;
    
    #Transcripts ID
    if ( $primary =~ m/^FBtr[0-9]+/ && $tr_id =~ m/^FBtr[0-9]+$/ ) {
        $data->{$primary}->{TranscriptID} = $tr_id;
        
        #Gene ID
        if ( $gene_id =~ m/^FBgn[0-9]+/ ) {
            $data->{$primary}->{GeneID} = $gene_id;
        }
        else {
            $parsed_error++;
            print "Error: invalid Gene ID at $entry\n";
            next;
        }
        
        #Exon ID
        if ( $exon_id =~ m/^\d+|\w+\:.+$/ ) {
            $data->{$primary}->{ExonID} = $exon_id;
        }
        else {
            $parsed_error++;
            print "Error: invalid transcript ID at $entry\n";
            next;
        }
        
        #Gene name
        if ( defined $gene_name ) {
            $data->{$primary}->{GeneName} = $gene_name;
        }
        else {
            $parsed_error++;
            print "Error: undefined gene_name at $entry\n";
            next;
        }
        
        #Chromosome
        if ( defined $chromosome ) {
            $data->{$primary}->{Chromosome} = $chromosome;
        }
        else {
            $parsed_error++;
            print "Error: undefined chromosome at $entry\n";
            next;
        }
        
        #Strand
        if ( $strand =~ m/\-1|1/ ) {
            $data->{$primary}->{Strand} = $strand;
        }
        else {
            $parsed_error++;
            print "Error: invalid strand at $entry\n";
            next;
        }
        
        #Gene start and end positions
        if ( $gene_start =~ m/^[0-9]+$/ && $gene_end =~ m/^[0-9]+$/ ) {
            my $region = sort_region($gene_start, $gene_end);
            
            $data->{$primary}->{Gene_region} = $region     if defined $region;
            $data->{$primary}->{GeneStart}   = $gene_start if defined $gene_start;
            $data->{$primary}->{GeneEnd}     = $gene_end   if defined $gene_end;
        }
        else {
            $parsed_error++;
            print "Error: could not found gene start/end region at $entry\n";
            next;
        }
        
        #5'UTR
        if ( $fiveUTR_Start =~ m/^[0-9]+$/ && $fiveUTR_End =~ m/^[0-9]+$/ ) {
            
            my $five_region = sort_region($fiveUTR_Start, $fiveUTR_End);
            $data->{$primary}->{'5UTR'}       = $five_region if defined $five_region;
            
            $data->{$primary}->{'5UTR_Start'} = $fiveUTR_Start;
            $data->{$primary}->{'3UTR_Start'} = $fiveUTR_End;
        }
        elsif ( defined $fiveUTR_Start ) {
            #hyphen means no-data
            $data->{$primary}->{'5UTR'}       = "-";
            $data->{$primary}->{'5UTR_Start'} = "-";
        }
        elsif ( defined $fiveUTR_End ) {
            $data->{$primary}->{'5UTR'}      = "-";
            $data->{$primary}->{'5UTR_End'}  = "-";
        }
        else {
            $parsed_error++;
            print "Error: 5UTR start/end(undefined) at $entry\n";
            die; #withhold
        }
        
        #3'UTR
        if ( $threeUTR_Start =~ m/^[0-9]+$/ && $threeUTR_End =~ m/^[0-9]+$/ ) {
            
            my $three_region = sort_region($threeUTR_Start, $threeUTR_End);
            $data->{$primary}->{'3UTR'} = $three_region if defined $three_region;
            
            $data->{$primary}->{'3UTR_Start'} = $threeUTR_Start;
            $data->{$primary}->{'3UTR_End'}   = $threeUTR_End;
        }
        elsif ( defined $threeUTR_Start ) {
            $data->{$primary}->{'3UTR'}       = "-";
            $data->{$primary}->{'3UTR_Start'} = "-";
        }
        elsif ( defined $threeUTR_End ) {
            $data->{$primary}->{'3UTR'}     = "-";
            $data->{$primary}->{'3UTR_End'} = "-";
        }
        else {
            $parsed_error++;
            print "Error: 3UTR Start/End at $entry\n";
            die;
        }
        
        #Exon postions
        if ( $ExonStart =~ m/^[0-9]+$/ && $ExonEnd =~ m/^[0-9]+$/ ) {
            my $exon_region = sort_region($ExonStart, $ExonEnd);
            $data->{$primary}->{Exon_region} = $exon_region if defined $exon_region;
            
            $data->{$primary}->{ExonStart} = $ExonStart;
            $data->{$primary}->{ExonEnd}   = $ExonEnd;
        }
        else {
            $parsed_error++;
            print "Error: exon start/end is not numetrical\n";
            next;
        }
    }
    else {
        $parsed_error++;
        print "Error: invalid transcript ID format at $entry\n";
        next; 
    }
}
close $fh_s;


my $header = "GeneID\tTranscriptID\tExonID\tGene Name\tStrand\tGene Start\tGene end\tExon Start\tExon end\t3'UTR\t5'UTR\tEvent name\n";
print $header;

##### Parsing flybase_structures file... #####
    
my %cachedPrimary;
my $REFERENCE;
my $AS_EXON;

my $FLAG_CONTINUE = 0;
my ($BEFORE_GENE_ID, $BEFORE_TRANSCRIPT_ID) = qw//;
  
LOAD:
while ( my $entry = <$fh_e> ) {
    next unless $entry =~ m/^FBgn[0-9]+/;
    
    my @t = split/\t/, $entry;
    
    my $gene_id       = $t[0];
    my $transcript_id = $t[1];
    my $conbined_id   = $t[2] if defined $t[2];
    my $chromosome    = $t[3];
    my $original_id   = $t[4];
    my $region_start  = $t[5];
    my $region_end    = $t[6];
    my $strand        = $t[7];
    my $event_name    = $t[8];
    
    #Transcripts ID
    if ( !$transcript_id =~ m/^FBtr[0-9]+/ ) {
        $parsed_error++;
        print "Error: invalid transcript ID at $entry\n";
        next LOAD;
    }
    
    #Gene ID
    if ( !$gene_id =~ m/^FBgn[0-9]+/ ) {
        $parsed_error++;
        print "Error: invalid Gene ID at $entry\n";
        next LOAD;
    }
    
    #Chromosome
    if ( !defined $chromosome ) {
        $parsed_error++;
        print "Error: undefined chromosome at $entry\n";
        next LOAD;
    }
    
    #Strand
    if ( !$strand =~ m/\-1|1/ ) {
        $parsed_error++;
        print "Error: invalid strand at $entry\n";
        next LOAD;
    }
    
    #gene start and end
    if ( !$region_start =~ m/^[0-9]+$/ && !$region_end =~ m/^[0-9]+$/ ) {
        $parsed_error++;
        next LOAD;
    }
    
    if ( defined $event_name ) {
        chomp $event_name;
    }
    else {
        $parsed_error++;
        print "Error: undefined event name: $entry\n";
        next LOAD;
    }

    if ( $BEFORE_GENE_ID && $BEFORE_TRANSCRIPT_ID
         && $BEFORE_GENE_ID eq $gene_id
         && $BEFORE_TRANSCRIPT_ID eq $transcript_id ) {
        $FLAG_CONTINUE = 1;
    }
    elsif ( $. == 2 ) {
        # [line No.2 => initialize BEFORE_* variables]
        ($BEFORE_GENE_ID, $BEFORE_TRANSCRIPT_ID) = ($gene_id, $transcript_id);
    }
    else {
        print $REFERENCE, $AS_EXON,"#\n";
        ($BEFORE_GENE_ID, $BEFORE_TRANSCRIPT_ID) = ($gene_id, $transcript_id);
        ($FLAG_CONTINUE, $REFERENCE, $AS_EXON) = (0, '', '');
    }

    my $FLAG_REFERENCE     = 'START';
    my $FLAG_SAME_POS_EXON = 0;
    my $THIS_EXON          = q//;
    
    
    my $known_exon   = 'known  ';
    my $unknown_exon = 'unknown';
        
 INTEGRATE:
    foreach my $key (
                     sort {
                         $data->{$a}->{GeneID} cmp $data->{$b}->{GeneID}
                             ||
                                 $data->{$a}->{TranscriptID} cmp $data->{$b}->{TranscriptID}
                                     ||
                                         $data->{$a}->{ExonStart} <=> $data->{$b}->{ExonStart}
                                             ||
                                                 $data->{$a}->{ExonEnd} <=> $data->{$b}->{ExonEnd}
                                             }
                     keys %{ $data } ) {
    
        unless ( $FLAG_CONTINUE ) {
            last if $FLAG_REFERENCE eq 'DONE';

            #FBgn ID and FBtr ID is equal
            if  ( $data->{$key}->{GeneID} eq $gene_id
                  && $data->{$key}->{TranscriptID} eq $transcript_id ) {
                
                # Join reference exon
                $REFERENCE .=
                    $data->{$key}->{GeneID}. "\t".
                        $data->{$key}->{TranscriptID}. " :Ref \t".
                            $known_exon. "\t".
                                $data->{$key}->{GeneName}. "\t".
                                    $data->{$key}->{Chromosome}. "\t".
                                        $data->{$key}->{Strand}. "\t".
                                            $data->{$key}->{GeneStart}. "\t".
                                                $data->{$key}->{GeneEnd}. "\t".
                                                    $data->{$key}->{ExonID}. " \t".
                                                        $data->{$key}->{ExonStart}. "\t".
                                                            $data->{$key}->{ExonEnd}. "\t".
                                                                $data->{$key}->{'3UTR'}. "\t".
                                                                    $data->{$key}->{'5UTR'}. "\n";
                
                $FLAG_REFERENCE = 'CONTINUE';
            }
            elsif ( $FLAG_REFERENCE eq 'CONTINUE' ) {
                $FLAG_REFERENCE = 'DONE';
            }
        }
        
        ##cached primary key
        # next if $cachedPrimary{$transcript_id.$gene_id};

        # Exon is used as AS
        # different length/positon from start and/or end
        if ( $data->{$key}->{GeneID} eq $gene_id
             && $data->{$key}->{TranscriptID} eq $transcript_id ) {
            
            if ( $data->{$key}->{ExonStart} != $region_start
                 && $data->{$key}->{ExonEnd} != $region_end
                 && $FLAG_SAME_POS_EXON != 1 ) {
                
                $THIS_EXON =
                    $data->{$key}->{GeneID}. "\t".
                        $data->{$key}->{TranscriptID}. " :AS!=\t".
                            $unknown_exon. "\t".
                                $data->{$key}->{GeneName}. "\t".
                                    $data->{$key}->{Chromosome}. "\t".
                                        $data->{$key}->{Strand}. "\t".
                                            $data->{$key}->{GeneStart}. "\t".
                                                $data->{$key}->{GeneEnd}. "\t".
                                                    "$gene_id.A". "\t".
                                                        $region_start. "\t".
                                                            $region_end. "\t".
                                                                $data->{$key}->{'3UTR'}. "\t".
                                                                    $data->{$key}->{'5UTR'}. "\t".
                                                                        $event_name."\n";
            }
            
            #AS exon positions is equal constitutive exon position
            #AS exon is mapping to ExonID of reference
            elsif ( $data->{$key}->{ExonStart} ==  $region_start
                    && $data->{$key}->{ExonEnd} == $region_end ) {
                
                $THIS_EXON =
                    $data->{$key}->{GeneID}. "\t".
                        $transcript_id. " :AS==\t".
                            $known_exon. "\t".
                                $data->{$key}->{GeneName}. "\t".
                                    $data->{$key}->{Chromosome}. "\t".
                                        $data->{$key}->{Strand}. "\t".
                                            $data->{$key}->{GeneStart}. "\t".
                                                $data->{$key}->{GeneEnd}. "\t".
                                                    $data->{$key}->{ExonID}. "\t".
                                                        $region_start. "\t".
                                                            $region_end. "\t".
                                                                $data->{$key}->{'3UTR'}. "\t".
                                                                    $data->{$key}->{'5UTR'}. "\t".
                                                                        $event_name. "\n";
                
                $FLAG_SAME_POS_EXON = 1;
                
                last if $FLAG_REFERENCE eq 'DONE';
            }
        }
    }
    
    $AS_EXON .= $THIS_EXON;
}
close $fh_e;


print $REFERENCE,$AS_EXON,"#\n";


#print Dumper $data;

print $parsed_error, "\n" if $parsed_error > 0;


sub sort_region {
    
    my $start = shift;
    my $end   = shift;
    
    if ( $start < $end ) {
        my $join = "$start..$end";
        
        return scalar $join;
    }
    elsif ( $start > $end ) {
        my $reversed_join = "$end..$start";
        
        return scalar $reversed_join;
    }
    else {
        return "Error: could not sort numetrically";
    }
}

sub help {
    
    my $msg = <<EOF;
this script is used for merging the two file that alternative splicing events data from Ensembl Biomart"
Usage:
      perl $0

Options:
     --help|-h : Show help page
          
EOF
    
    return scalar $msg;
}

