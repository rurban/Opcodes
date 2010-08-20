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
    ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
     ('META_MERGE'  => {
       resources =>
       {
	 license     => 'http://dev.perl.org/licenses/',
	 repository  => 'http://github.com/rurban/Opcodes',
       },
      }
     ) : ()),
  );

sub MY::depend { "README : lib/Opcode.pm\n\tpod2text lib/Opcode.pm > README\n"; }
