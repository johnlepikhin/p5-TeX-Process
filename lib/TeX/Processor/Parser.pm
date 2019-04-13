package TeX::Processor::Parser;

use warnings;
use strict;

our $VERSION = '0.01';

use Data::Dumper;
use Carp qw(cluck croak confess);

use Syntax::NamedArgs qw(get_arg get_arg_opt);

sub lexer {
    my $s  = shift;
    my $id = shift;

    my $line = 1;
    my @history;
    my @backlog;

    my $tokenizer = sub {
    LEXER: {
            if ( $s =~ m{\G \{ }gcx ) {
                return { type => 'L_BRACE', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \} }gcx ) {
                return { type => 'R_BRACE', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \[ }gcx ) {
                return { type => 'L_SQ_BRACKET', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \] }gcx ) {
                return { type => 'R_SQ_BRACKET', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \$ }gcx ) {
                return { type => 'DOLLAR', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \# }gcx ) {
                return { type => 'HASH', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \^ }gcx ) {
                return { type => 'CARET', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \& }gcx ) {
                return { type => 'AMPERSAND', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G _ }gcx ) {
                return { type => 'UNDERSCORE', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G ~ }gcx ) {
                return { type => 'TILDA', startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \\ \\ }gcx ) {
                return { type => 'TEXT', content => '\\\\', startpos => ( pos $s ) - 2, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \\ \& }gcx ) {
                return { type => 'TEXT', content => '&', startpos => ( pos $s ) - 2, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \\ \$ }gcx ) {
                return { type => 'TEXT', content => '$', startpos => ( pos $s ) - 2, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \\ \{ }gcx ) {
                return { type => 'TEXT', content => '{', startpos => ( pos $s ) - 2, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \\ \} }gcx ) {
                return { type => 'TEXT', content => '}', startpos => ( pos $s ) - 2, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \\ ([[:alpha:]]+) }gcx || $s =~ m{\G \\ ([~^]) }gcx ) {
                return { type => 'COMMAND', command => $1, startpos => ( pos $s ) - length $1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G % ([^\n]+) }gcx ) {
                return { type => 'COMMENT', content => $1, startpos => ( pos $s ) - 1 - length $1, endpos => ( pos $s ), line => $line };
            }
            if ( $s =~ m{\G \n }gcx ) {
                $line++;
                return { type => 'TEXT', content => "\n", startpos => ( pos $s ) - 1, endpos => ( pos $s ), line => $line - 1 };
            }
            if ( $s =~ m{\G ([^#\$%^&_{}\[\]~\n\\]+) }gcx ) {
                return { type => 'TEXT', content => $1, startpos => ( pos $s ) - length $1, endpos => ( pos $s ), line => $line };
            }

            my ($substr) = $s =~ m{\G(.{1,20})};
            if ( ! defined $substr ) {
                return;
            }
            my $min = ( pos $s ) - 40;
            if ( $min < 0 ) { $min = 0 }
            my $context = substr $s, $min, 80;
            croak( sprintf q{Unexpected token in %s at line %i, pos %i : %s : %s}, $id, $line, pos $s, $substr, $context );
        }
    };

    my $get = sub {
        my $token;
        if (@backlog) {
            $token = pop @backlog;
        } else {
            $token = $tokenizer->();
        }

        if ( defined $token ) {
            push @history, $token;
        }

        return $token;
    };

    return {
        get      => $get,
        last     => sub { $history[-1] },
        rollback => sub { push @backlog, pop @history },
    };
}

sub parse {
    my $s             = get_arg document          => @_;
    my $id            = get_arg_opt id            => 'unidentified document', @_;
    my $error_context = get_arg_opt error_context => 40, @_;

    my $lexer = lexer( $s, $id );

    my ( $parse_base, $parse_command, $parse_command_args );

    my $debug = sub {
        if ( $ENV{DEBUG} ) {
            print "@_\n";
        }
    };

    my $parse_error = sub {
        my $token = get_arg_opt token => $lexer->{last}->(), @_;
        my $msg = get_arg msg => @_;

        my $offset = $error_context;
        my $min;
        if ( $token->{startpos} > $offset ) {
            $min = $token->{startpos} - $offset;
        } else {
            $min    = 0;
            $offset = $token->{startpos};
        }
        my $context = substr $s, $min, $error_context * 2;
        substr $context, $offset, 1, '<<<' . ( substr $context, $offset, 1 ) . '>>>';

        confess( "$msg in $id at " . ( Dumper $token) . ": $context" );
    };

    my $parse_eof_error = sub {
        $parse_error->( @_, msg => "Unexpected end of document" );
    };

    my $parse_group = sub {
        my $begin = get_arg begin => @_;
        my $end   = get_arg end   => @_;
        $debug->("parse_group $begin..$end");
        my $token = $lexer->{get}();

        if ( ! defined $token ) {
            return;
        }

        if ( $token->{type} ne $begin ) {
            $lexer->{rollback}();
            return;
        }

        my $arg = $parse_base->( @_, stop_check => sub { $_[0]->{type} eq $end } );

        return $arg;
    };

    $parse_command = sub {
        $debug->('parse_command');
        my $command = shift;

        my @args;
        while ( defined( my $token = $lexer->{get}() ) ) {
            if ( $token->{type} eq 'L_SQ_BRACKET' ) {
                $lexer->{rollback}();
                my $arg = {
                    content => $parse_group->( begin => 'L_SQ_BRACKET', end => 'R_SQ_BRACKET' ),
                    type    => 'bracket'
                };
                push @args, $arg;
                next;
            }
            if ( $token->{type} eq 'L_BRACE' ) {
                $lexer->{rollback}();
                my $arg = {
                    content => $parse_group->( begin => 'L_BRACE', end => 'R_BRACE' ),
                    type    => 'brace'
                };
                push @args, $arg;
                next;
            }

            $lexer->{rollback}();
            last;
        }

        $command->{args} = \@args;

        return $command;
    };

    $parse_base = sub {
        my $stop_check = get_arg_opt stop_check => sub {0}, @_;

        my @r;
        while ( defined( my $token = $lexer->{get}() ) ) {
            if ( $stop_check->($token) ) {
                last;
            }

            if ( $token->{type} eq 'L_SQ_BRACKET' ) {
                $token->{type}    = 'TEXT';
                $token->{content} = q{[};
            }
            if ( $token->{type} eq 'R_SQ_BRACKET' ) {
                $token->{type}    = 'TEXT';
                $token->{content} = q{]};
            }

            if (   $token->{type} eq 'HASH'
                || $token->{type} eq 'CARET'
                || $token->{type} eq 'AMPERSAND'
                || $token->{type} eq 'UNDERSCORE'
                || $token->{type} eq 'TILDA' ) {
                push @r, $token;
                next;
            }

            if ( $token->{type} eq 'TEXT' || $token->{type} eq 'COMMENT' ) {
                push @r, $token;
                next;
            }

            if ( $token->{type} eq 'COMMAND' ) {
                my $command = $parse_command->($token);
                push @r, $command;
                next;
            }
            if ( $token->{type} eq 'L_BRACE' ) {
                $lexer->{rollback}();
                my $children = $parse_group->( begin => 'L_BRACE', end => 'R_BRACE' );
                my $group = $token;
                $group->{type}     = 'GROUP';
                $group->{children} = $children;
                push @r, $group;
                next;
            }

            if ( $token->{type} eq 'DOLLAR' ) {
                $lexer->{rollback}();
                my $children = $parse_group->( begin => 'DOLLAR', end => 'DOLLAR', in_math => 1 );
                my $group = $token;
                $group->{type}     = 'MATH';
                $group->{children} = $children;
                push @r, $group;
                next;
            }

            $parse_error->( msg => "Unexpected token" );
        }

        return \@r;
    };

    $parse_base->();
}

1;
