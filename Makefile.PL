use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Opcodes',
    VERSION_FROM  => 'lib/Opcodes.pm',
    ABSTRACT_FROM => 'lib/Opcodes.pm',
    INSTALLDIRS   => 'perl',
    SIGN          => 1,
    AUTHOR        => 'Reini Urban',
    LICENSE       => 'perl',
);
