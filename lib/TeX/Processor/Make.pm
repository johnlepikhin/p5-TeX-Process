package TeX::Processor::Make;

use warnings;
use strict;

our $VERSION = '0.01';

use Syntax::NamedArgs qw(get_arg get_arg_opt);

sub text {
    return { type => 'TEXT', content => $_[0] };
}

sub command {
    my $command = get_arg command => @_;
    my $args = get_arg_opt args => [], @_;

    return {
        type    => 'COMMAND',
        command => $command,
        args    => $args,
    };
}

sub group {
    my $children = get_arg_opt children => [], @_;

    return {
        type     => 'GROUP',
        children => $children,
    };
}

1;
