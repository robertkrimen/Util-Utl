package Util::Utl;

use strict;
use warnings;

use List::Util;
use List::MoreUtils;
use Scalar::Util;
use Package::Pkg;
use Carp qw/ croak confess /;

sub import {
    my $package = caller;
    pkg->install( code => sub { __PACKAGE__ }, into => $package, as => 'utl' );
}

sub first {
    my $self = shift;
    goto &List::Util::first if ref $_[0] eq 'CODE';
    unshift @_, $self;
    goto &_first_hash if ref $_[1] eq 'HASH';
    confess "Invalid invocation: first (@_)";
}

sub _first_hash {
    my $self = shift;
    my $hash = shift;
    my @query = @_;
    my $options = {};
    $options = pop @query if ref $query[-1] eq 'HASH';

    my $test = $options->{ test };
    my $exclusive = $options->{ exclusive };

    my @found;
    for ( @query ) {
        if ( exists $hash->{ $_ } ) {
            next if $test and ! $test->( $hash->{ $_ }, $_, $hash );
            push @found, $_;
            last if not $exclusive;
        }
    }

    if ( $exclusive && @found > 1 ) {
        if ( ref $exclusive eq 'CODE' ) {
            return $exclusive->( $hash, @found );
        }
        else {
            croak "first: Found non-exclusive keys (@found) in hash\n";
        }
    }

    return $hash->{ $found[0] };
}

{
    my $install = sub {
        my $package = shift;
        my @export = @_;
        @export = eval "\@${package}::EXPORT_OK" if not @export;
        for my $method ( @export ) {
            next if __PACKAGE__->can( $method );
            no strict 'refs';
            *$method = eval qq/sub { shift; goto &${package}::$method };/;
        }
    };

    $install->( 'List::Util' );
    $install->( 'List::MoreUtils' );
    $install->( 'Scalar::Util' );
    $install->( 'String::Util' );
}

1;
