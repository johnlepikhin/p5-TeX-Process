
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('TeX::Processor::Parser');
    use_ok('TeX::Processor::Printer');
    use_ok('TeX::Processor::Make');
    use_ok('TeX::Processor');
}

my $tests_count = 4;

sub tex_to_tex {
    my $doc = TeX::Processor::Parser::parse( document => $_[0] );
    TeX::Processor::Printer::latex( document => $doc );
}

my @tests = (
    'empty document'                 => q{},
    'plain text'                     => "plaintext",
    'single command without args'    => "\\tiny",
    'single command with one arg'    => "\\textbf{text}",
    'single command with many args'  => "\\cmd{arg1}{arg2}{arg3}",
    'single command with mixed args' => "\\cmd{arg1}[arg2]{arg3}[arg4]",
    'group'                          => "{ group content }",
    'special characters'             => "`~!\@#^&*()_-+= \\\\ []",
    'math'                           => '$2^2 = \\five$',
    'escaped'                        => "\\~ \\& \\{ \\} \\\$",
    'nested groups'                  => '{{{{}}}}',
    'nested commands'                => '\\textbf{\\textit{\\begin{environment}text\\end{environment}}}',
    'comments and newlines'          => "test % comment\n% comment with \\command{}\n\\command before % comment\n\n\n",
);

while ( defined( my $name = shift @tests ) ) {
    my $doc = shift @tests;
    is( tex_to_tex($doc), $doc, "Parser+printer of '$name'" );
    $tests_count++;
}

is( TeX::Processor::Printer::latex( document => [ TeX::Processor::Make::text('test') ] ), 'test', 'make text' );
is( TeX::Processor::Printer::latex( document => [ TeX::Processor::Make::command( command => 'tiny' ) ] ),
    '\\tiny', 'make simple command without args' );
is( TeX::Processor::Printer::latex(
        document => [
            TeX::Processor::Make::group(
                children => [
                    TeX::Processor::Make::text('test'),
                    TeX::Processor::Make::command(
                        command => 'cmd',
                        args    => [
                            { type => 'brace',   content => [] },
                            { type => 'bracket', content => [] },
                            { type => 'brace',   content => [ TeX::Processor::Make::text('test') ] },
                        ] ) ] ) ]
    ),
    '{test\\cmd{}[]{test}}',
    'make complex AST'
);
$tests_count += 3;

done_testing($tests_count);
