#!/usr/bin/env perl
# ABSTRACT: Compute distance matrix for any distance metric
=head1 NAME

Algorithm::DistanceMatrix - Compute distance matrix for any distance metric

=head1 SYNOPSIS

use Algorith::DistanceMatrix;
my $m = Algorithm::DistanceMatrix->new(
    metric=>\&mydistance,objects=\@myarray);
my $distmatrix =  $m->distancematrix;

use Algorithm::Cluster qw/treecluster/;
# method=>
# s: single-linkage clustering
# http://en.wikipedia.org/wiki/Single-linkage_clustering
# m: maximum- (or complete-) linkage clustering
# http://en.wikipedia.org/wiki/Complete_linkage_clustering
# a: average-linkage clustering (UPGMA)
# http://en.wikipedia.org/wiki/UPGMA

my $tree = treecluster(data=>$distmat, method=>'a');

# Get your objects and the cluster IDs they belong to, assuming 5 clusters
my $cluster_ids = $tree->cut(5);

=head1 DESCRIPTION

This is a small helper package for L<Algorithm::Cluster>, which provides many 
facilities for clustering data. It also provides a C<distancematrix> function,
but assumes tabular data, which is the standard for gene expression data. 

If your data is tabular, you should first have a look at C<distancematrix> in
L<Algorithm::Cluster>

 http://cpansearch.perl.org/src/MDEHOON/Algorithm-Cluster-1.48/doc/cluster.pdf
 
Otherwise, this package provides a simple distance matrix, given an arbitrary 
distance function. It does not assume anything about your data. You simply 
provide a callback function for measuring the distance between any two objects.
It produces a lower diagonal (by default) distance matrix that is fit to be used
by the clustering algorithms of L<Algorithm::Cluster>.

=cut

package Algorithm::DistanceMatrix;
our $VERSION = '0.01_01';
use Moose;

=head2 mode

One of C<qw/lower upper full/> for a lower diagonal, upper diagonal, or full 
distance matrix.

=cut
has 'mode' =>(
    is => 'rw',
    isa => 'Str',
    default => 'lower',
    );

  
=head2 metric

Callback for computing the distance, similarity, or whatever measure you like.

 $matrix->metrix(\@mydistance);

Where C<mydistance> receives two objects as it's first two arguments.
 
If you need to pass special parameters to your method:

 $matrix->metric(sub{my($x,$y)=@_;mydistance(first=>$x,second=>$y,mode=>'fast')};
 
You may use any metric, and may return any number or object. Note that if you 
plan to use this with L<Algorithm::Cluster> this needs to be a distance metric.
So, if you're measure how similar two things are, on a scale of 1-10, then you
should return C<10-$similarity> to get a distance.

=cut
has 'metric' => (
    is=>'rw',
    isa=>'CodeRef',
    );


=head2 objects

Array reference. Doesn't matter what kind of objects are in the array, as long
as your C<metric> can process them.
=cut
has 'objects' => (
    is => 'rw',
    isa => 'ArrayRef',
    );
    
    
=head2 distancematrix

2D array of distances (or similarities, or whatever) between your objects.

(An ArrayRef of ArrayRefs.)

=cut    
sub distancematrix {
    my ($self, ) = @_;
    my $measure = $self->measure;
    my $objects = $self->objects;
    # Lower diagonal distance matrix
    my $distances = [];
    for (my $i = 0; $i < @$objects; $i++) {
        $distances->[$i] ||= [];
        my $start = $self->mode =~ /full/i ? 0 : $i+1;
        for (my $j = $start; $j < @$objects; $j++) {
            my $ref = \$distances->[$i][$j];
            # Swap i and j if lower diagonal (default)
            $ref = \$distances->[$j][$i] if $self->mode =~ /lower/i;     
            $$ref = $measure->($objects->[$i], $objects->[$j]);
        }
    }
    return $distances;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
