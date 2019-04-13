package TeX::Processor;

use warnings;
use strict;

our $VERSION = '0.01';

use Syntax::NamedArgs qw(get_arg get_arg_opt);

sub map_commands {
    my $map = get_arg_opt map => {}, @_;
    my $unified = get_arg_opt unified => sub {0}, @_;
    my $list    = get_arg list        => @_;
    my %args    = @_;

    my $mapper = sub {
        my $node = $_;

        if ( $node->{type} eq 'GROUP' ) {
            $node->{children} = map_commands( %args, list => $node->{children} );
        }

        if ( $node->{type} eq 'COMMAND' ) {
            if ( exists $map->{ $node->{command} } ) {
                return $map->{ $node->{command} }($node);
            }
            my ( $changed, @new_content ) = $unified->($node);
            if ($changed) {
                return @new_content;
            }

            foreach ( @{ $node->{args} } ) {
                $_->{content} = map_commands( %args, list => $_->{content} );
            }
        }

        return $node;
    };

    return [ map { $mapper->($_) } @{$list} ];
}
