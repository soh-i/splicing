#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

my $infile = shift or die;

open my $fh, '<', $infile || die "Can not read $infile: $!";

my $error_count = 0;
my $data;

while ( my $entry = <$fh> ) {
    #skip header
    next if $entry =~ m/^#/;
    
    my @t = split /\t/, $entry;
    
    if ( defined $t[2] ) {
        my $gene_name = $t[2];
        
        #$data->{$gene_name}->{Novel}  = $t[0];
        #$data->{$gene_name}->{Type}   = $t[1];
        #$data->{$gene_name}->{Chr}    = $t[3];
        #$data->{$gene_name}->{Strand} = $t[4];
        
        push @{ $data->{Entry}->{$gene_name}->{Type} }, $t[1];
        push @{ $data->{Entry}->{$gene_name}->{Chr} }, $t[3];
        push @{ $data->{Entry}->{$gene_name}->{Strand} }, $t[4];
    }
}
print Dumper $data;

__END__
    printf "%-3s\t", $t[0];
    printf "%-20s\t", $t[1];
    printf "%-25s\t", $t[2];
    printf "%-3s\t", $t[3];
    printf "%-3s\t", $t[4];
    
    print "#EJ# $t[5]\t";
    print "#IJ# $t[6]\t";
    print "#EE# $t[7]\t";
    print "#IE# $t[8]\t";
    print "#IJ# $t[9]\t";
    print "NCE# $t[10]\t";
    print "\n";
    
}

    
## Parse each column strings

if ( $t[2] =~ m/.+/ ) {
        my $gene_name = $t[2];
        
        
        $data->{$gene_name}->{exclusion_junction} = [ split /\;/, $t[5] ];
        $data->{$gene_name}->{inclusion_junction} = [ split /\;/, $t[6] ];
        $data->{$gene_name}->{exclusion_exon} = [ split /\;/, $t[7] ];
        $data->{$gene_name}->{inclusion_exon} = [ split /\;/, $t[8] ];
        $data->{$gene_name}->{IntronExon_junction} = [ split /\;/, $t[9] ];
        $data->{$gene_name}->{neighboring_constitutive_exons} = [ split /\;/, $t[10] ];
        
        
    }

}
print $data->{'spn-A'}->{Strand}, "\n";
print $data->{'spn-A'}->{exclusion_junction}->[0], " EJ\n";
print $data->{'spn-A'}->{inclusion_junction}->[0], " IJ\n";
print $data->{'spn-A'}->{inclusion_exon}->[0], " IE\n";
print $data->{'spn-A'}->{exclusion_exon}->[0], " EE\n";

#print Dumper $data;

__END__
    elsif ( $t[2] =~ m/\s+/ ) {
        my $none_count = 0;
        $none_count++;
        my $name = "none";
        $name = $name.$none_count;
        push @{ $data->{Entry} }, $name;
        
    }
    else {
        #print $entry;
        #print "Error: invalid gene name";
        
    }    
    
    if ( $t[0] =~ m/[KN]/ ) {
        my $Contains_Novel_or_Only_Known_Junctions = $t[0];
    }
    else {
        $error_count++;
        #print $entry;
        #print "Error: invalid strings at 1st column";
        #die;
    }
    
    if ( $t[1] =~ m/\w+/ ) {
        my $as_event_type = $t[1];
    }
    else {
        #print $entry;
        #print "Error: invalid AS type at 2nd column";
        #die;
    }
    
    
    
    if ( $t[3] =~ m/chr.+/ ) {
        my $chr = $t[3];
    }
    else {
        #print $entry;
        #print "Error: Invalid chromosome name";
        #die;
    }
    
    
}

print Dumper sort $data;
