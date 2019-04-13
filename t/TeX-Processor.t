
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
    'empty document'                 => '',
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
    is( tex_to_tex($doc), $doc, "Testing '$name'" );
    $tests_count++;
}

done_testing($tests_count);
