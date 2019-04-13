package TeX::Processor::Printer;

use warnings;
use strict;

our $VERSION = '0.01';

use Data::Dumper;
use Carp qw(cluck croak confess);

use Syntax::NamedArgs qw(get_arg get_arg_opt);

sub latex {
    my $document = get_arg document => @_;

    my $printer;
    $printer = sub {
        my $lexema = shift;

        if ( $lexema->{type} eq 'TEXT' ) {
            if ( $lexema->{content} eq '&' ) {
                return "\\&";
            }
            if ( $lexema->{content} eq '$' ) {
                return "\\\$";
            }
            if ( $lexema->{content} eq '{' ) {
                return "\\{";
            }
            if ( $lexema->{content} eq '}' ) {
                return "\\}";
            }
            return $lexema->{content};
        }

        if ( $lexema->{type} eq 'TILDA' ) {
            return q{~};
        }
        if ( $lexema->{type} eq 'HASH' ) {
            return q{#};
        }
        if ( $lexema->{type} eq 'CARET' ) {
            return q{^};
        }
        if ( $lexema->{type} eq 'AMPERSAND' ) {
            return q{&};
        }
        if ( $lexema->{type} eq 'UNDERSCORE' ) {
            return q{_};
        }
        if ( $lexema->{type} eq 'L_SQ_BRACKET' ) {
            return q{[};
        }
        if ( $lexema->{type} eq 'R_SQ_BRACKET' ) {
            return q{]};
        }

        if ( $lexema->{type} eq 'COMMENT' ) {
            return "%$lexema->{content}";
        }

        if ( $lexema->{type} eq 'GROUP' ) {
            return '{' . ( join q{}, map { $printer->($_) } @{ $lexema->{children} } ) . '}';
        }
        if ( $lexema->{type} eq 'MATH' ) {
            return q{$} . ( join q{}, map { $printer->($_) } @{ $lexema->{children} } ) . q{$};
        }

        if ( $lexema->{type} eq 'COMMAND' ) {
            my $r = "\\$lexema->{command}";
            foreach my $arg ( @{ $lexema->{args} } ) {
                my $content = join q{}, map { $printer->($_) } @{ $arg->{content} };
                if ( $arg->{type} eq 'brace' ) {
                    $r .= "{$content}";
                    next;
                }
                if ( $arg->{type} eq 'bracket' ) {
                    $r .= "[$content]";
                    next;
                }
            }
            return $r;
        }

        confess "Unknown lexema type $lexema->{type}";
    };

    my $r = q{};
    foreach ( @{$document} ) {
        $r .= $printer->($_);
    }

    return $r;
}

sub flatten {
    my $document = get_arg document => @_;

    my $printer;
    $printer = sub {
        my $lexema = shift;

        if ( $lexema->{type} eq 'TEXT' ) {
            if ( $lexema->{content} eq '&' ) {
                return "&";
            }
            if ( $lexema->{content} eq '$' ) {
                return "\$";
            }
            if ( $lexema->{content} eq '{' ) {
                return "{";
            }
            if ( $lexema->{content} eq '}' ) {
                return "}";
            }
            my $r = $lexema->{content};
            $r =~ s{~}{ }g;
            return $r;
        }

        if ( $lexema->{type} eq 'TILDA' ) {
            return q{ };
        }
        if ( $lexema->{type} eq 'HASH' ) {
            return q{#};
        }
        if ( $lexema->{type} eq 'CARET' ) {
            return q{^};
        }
        if ( $lexema->{type} eq 'AMPERSAND' ) {
            return q{&};
        }
        if ( $lexema->{type} eq 'UNDERSCORE' ) {
            return q{_};
        }
        if ( $lexema->{type} eq 'L_SQ_BRACKET' ) {
            return q{[};
        }
        if ( $lexema->{type} eq 'R_SQ_BRACKET' ) {
            return q{]};
        }

        if ( $lexema->{type} eq 'COMMENT' ) {
            return q{};
        }

        if ( $lexema->{type} eq 'GROUP' ) {
            return join q{}, map { $printer->($_) } @{ $lexema->{children} };
        }
        if ( $lexema->{type} eq 'MATH' ) {
            return '$some formula here$';
        }

        if ( $lexema->{type} eq 'COMMAND' ) {
            my $r = q{};
            foreach my $arg ( @{ $lexema->{args} } ) {
                my $content = join q{}, map { $printer->($_) } @{ $arg->{content} };
                if ( $arg->{type} eq 'brace' ) {
                    $r .= " $content";
                    next;
                }
                if ( $arg->{type} eq 'bracket' ) {
                    $r .= " $content";
                    next;
                }
            }
            return $r;
        }

        confess "Unknown lexema type $lexema->{type}";
    };

    my $r = q{};
    foreach ( @{$document} ) {
        $r .= $printer->($_);
    }

    return $r;
}

1;
