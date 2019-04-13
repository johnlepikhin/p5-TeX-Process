use 5.024001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'TeX::Processor',
    VERSION_FROM  => 'lib/TeX/Processor/Parser.pm',
    ABSTRACT_FROM => 'lib/TeX/Processor/Parser.pm',
    PREREQ_PM     => { 'Syntax::NamedArgs' => 0.01 },
    AUTHOR        => 'Evgenii Lepikhin <johnlepikhin@gmail.com>',
    LICENSE       => 'perl',
);
