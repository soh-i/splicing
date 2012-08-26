#!/usr/bin/env perl

use strict;
use warnings;

use 5.12.4;

use Data::Dumper;

my $structures_file = '/home/soh.i/melanogaster/flybase_structures.tsv';
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
            $data->{$primary}->{'5UTR'} = $five_region if defined $five_region;
            
            #$data->{$transcript_id}->{'5UTR_Start'} = $fiveUTR_Start;
            #$data->{$transcript_id}->{'3UTR_Start'} = $fiveUTR_End;
        }
        elsif ( defined $fiveUTR_Start ) {
            #hyphen means no-data
            $data->{$primary}->{'5UTR'} = "-";
            #$data->{$transcript_id}->{'5UTR_Start'}  = "-";
        }
        elsif ( defined $fiveUTR_End ) {
            $data->{$primary}->{'5UTR'} = "-";
            #$data->{$transcript_id}->{'5UTR_End'}  = "-";
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
            
            #$data->{$transcript_id}->{'3UTR_Start'} = $threeUTR_Start;
            #$data->{$transcript_id}->{'3UTR_End'}   = $threeUTR_End;
        }
        elsif ( defined $threeUTR_Start ) {
            $data->{$primary}->{'3UTR'} = "-";
            #$data->{$transcript_id}->{'3UTR_Start'} = "-";
        }
        elsif ( defined $threeUTR_End ) {
            $data->{$primary}->{'3UTR'} = "-";
            #$data->{$transcript_id}->{'3UTR_End'} = "-";
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
        print "Error: invalid transcript ID at $entry\n";
        next;
    }
}


my %cachedPrimary;

##### Parsing flybase_structures file... #####
LOAD:
while ( my $entry = <$fh_e> ) {
    next unless $entry =~ m/^FBgn[0-9]+/;

    my @t = split/\t/, $entry;
    
    my $gene_id       = $t[0];
    my $transcript_id = $t[1];
    my $chromosome    = $t[3];
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
    
    ##cached primary key
    if ( $cachedPrimary{$transcript_id.$gene_id} ) {
        next LOAD;
    }
    else {
        $cachedPrimary{$transcript_id.$gene_id}++;
    }
    
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
        
        #FBgn ID and FBtr ID is equal
        if  ( $data->{$key}->{TranscriptID} eq $transcript_id
              && $data->{$key}->{GeneID} eq $gene_id ) {
            
            #reference file
            print $data->{$key}->{TranscriptID}, " :R   \t";
            print $data->{$key}->{ExonID}, "\t";
            print $data->{$key}->{GeneName}, "\t";
            print $data->{$key}->{ExonStart}, "\t";
            print $data->{$key}->{ExonEnd}, "\t";
            print "\n";
            
           # next;

            # Exon is used as AS
            # different length/positon from start and/or end
            if ( $data->{$key}->{ExonStart} != $region_start
                 && $data->{$key}->{ExonEnd} != $region_end ) {

                print $data->{$key}->{TranscriptID}, " :ASSM\t";
                print $data->{$key}->{ExonID}, "\t";
                print $data->{$key}->{GeneName}, "\t";
                print $region_start, "\t";
                print $region_end, "\t";
                print $event_name, "\t";
                print "\n";
                
            }
            
            #AS exon positions is equal constitutive exon position
            #AS exon is mapping to ExonID of reference
            elsif ( $data->{$key}->{ExonStart} ==  $region_start
                    && $data->{$key}->{ExonEnd} == $region_end ) {
                
                print $transcript_id, " :ASDF\t";
                print $data->{$key}->{ExonID}, "\t";
                print $data->{$key}->{GeneName}, "\t";
                print $region_start, "\t";
                print $region_end, "\t";
                print $event_name, "\t";
                print "\n";
                
                
            }

        }
        else {
            next ;
        }

    }
    print "#\n";
}

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
        return "Error:";
    }
}

sub help {
    
    my $msg = <<EOF;
this script is used for merging the two Alternative splicing events data from Ensembl Biomart"
Usage:
      perl $0 <in.data> 
          
EOF
    
    return scalar $msg;
}


