use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Opcode',
    VERSION_FROM  => 'lib/Opcode.pm',
    ABSTRACT_FROM => 'lib/Opcode.pm',
    INSTALLDIRS   => 'perl',
    SIGN          => 1,
    AUTHOR        => 'Malcolm Beattie, Tim Bunce, Reini Urban',
    LICENSE       => 'perl',
    realclean     => {FILES => 'Makefile.PL'},
);
