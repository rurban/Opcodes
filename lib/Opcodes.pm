package Opcodes;

use 5.006_001;
use strict;

our($VERSION, @ISA, @EXPORT, @EXPORT_OK);

$VERSION = "0.02";

use Carp;
use Exporter ();
use XSLoader ();
use Opcode ();

BEGIN {
    @ISA = qw(Exporter);
    @EXPORT =
      qw(opcodes opname opname2code opflags opaliases
	 opargs opclass opdesc opname
	);
    @EXPORT_OK = qw(ppaddr check argnum);
}
use subs @EXPORT_OK;

XSLoader::load 'Opcodes', $VERSION;

our @opcodes = opcodes();

sub opname {
    $opcodes[ $_[0] ]->[1];
}

sub ppaddr {
    $opcodes[ $_[0] ]->[2];
}

sub check {
    $opcodes[ $_[0] ]->[3];
}

sub opdesc {
    Opcode::opdesc( opname( $_[0] ));
}

sub opargs {
    $opcodes[ $_[0] ]->[4];
}

# n no_stack - A handcoded list of ops without any SP handling (Note: stack_base is allowed),
# i.e. no args + no return values.
# 'n' 512 is not encoded in opcode.pl. We could add it but then we would have to
# maintain it in CORE as well as here. Here its is needed for older perls. So
# keep it this way.
our %no_stack = map{$_=>1}qw[null enter unstack leave scope lineseq
  next redo goto break continue entertry nextstate dbstate pushmark
  regcmaybe regcreset];
# S retval may be scalar. s and i are automatically included
our %retval_scalar = map{$_=>1}qw[];
# A retval may be array
our %retval_array = map{$_=>1}qw[];
# V retval may be void
our %retval_void = map{$_=>1}qw[];
# F fixed retval type (S, A or V)
our %retval_fixed = map{$_=>1}qw[];

sub opflags {
    # 0x1ff = 9 bits OCSHIFT
    my $flags =  opargs($_[0]) & 0x1ff;
    # now the extras
    my $opname = opname($_[0]);
    $flags += 512 if $no_stack{$opname};
    $flags += 1024 if $retval_scalar{$opname} or $flags & 20; # 4|16
    $flags += 2048 if $retval_array{$opname};
    $flags += 4096 if $retval_void{$opname};
    return $flags;
}

# See F<opcode.pl> for $OASHIFT and $OCSHIFT. For flags n 512 we
# would have to change that.
sub opclass {
    my $OCSHIFT = 9; # 1e00 = 13-9=4 bits left-shifted by 9
    (opargs($_[0]) & 0x1e00) >> $OCSHIFT;
}

sub argnum {
    #my $ARGSHIFT = 4;
    my $OASHIFT = 13;
    #my $ARGBITS = 32; # ffffe000 = 32-13 bits left-shifted by 13
    (opargs($_[0]) & 0xffffe000) >> $OASHIFT;
}

sub opaliases {
    my $op = shift;
    my @aliases = ();
    my $ppaddr = ppaddr($op);
    for (@opcodes) {
      push @aliases, ($_->[0]) 
        if $_->[2] == $ppaddr and $_->[0] != $op;
    }
    @aliases;
}

sub opname2code {
    my $name = shift;
    for (0..$#opcodes) { return $_ if opname($_) eq $name; }
    return undef;
}

1;
__END__

=head1 NAME

Opcodes - Opcodes information from opnames.h and opcode.h

=head1 SYNOPSIS

  use Opcodes;
  print "Empty opcodes are null and ",
    join ",", map {opname $_}, opaliases(opname2code('null'));

=head1 DESCRIPTION

=head1 Operator Names and Operator Lists

The canonical list of operator names is the contents of the array
PL_op_name, defined and initialised in file F<opcode.h> of the Perl
source distribution (and installed into the perl library).

Each operator has both a terse name (its opname) and a more verbose or
recognisable descriptive name. The opdesc function can be used to
return a the description for an OP.

=over 8

=item an operator name (opname)

Operator names are typically small lowercase words like enterloop,
leaveloop, last, next, redo etc. Sometimes they are rather cryptic
like gv2cv, i_ncmp and ftsvtx.

=item an OP opcode

The opcode information functions all take the integer code, 0..MAX0.

=back


=head1 Opcode Information

Retrieve information of the Opcodes. All are available for export by the package.
Functions names starting with "op" are automatically exported.

=over 8

=item opcodes

In a scalar context opcodes returns the number of opcodes in this
version of perl (361 with perl-5.10).

In a list context it returns a list of all the operators with
its properties, a list of [ opcode opname ppaddr check opargs ].

=item opname (OP)

Returns the lowercase name without pp_ for the OP,
an integer between 0 and MAXO.

=item ppaddr (OP)

Returns the address of the ppaddr, which can be used to
get the aliases for each opcode.

=item check (OP)

Returns the address of the check function.

=item opdesc (OP)

Returns the description of the OP.

=item opargs (OP)

Returns the opcode args encoded as integer of the opcode.
See below or F<opcode.pl> for the encoding details.

  opflags 1-128 + opclass 1-13 << 9 + argnum 1-15.. << 13

=item argnum (OP)

Returns the arguments and types encoded as number acccording
to the following table, 4 bit for each argument.

    'S',  1,		# scalar
    'L',  2,		# list
    'A',  3,		# array value
    'H',  4,		# hash value
    'C',  5,		# code value
    'F',  6,		# file value
    'R',  7,		# scalar reference

  + '?',  8,            # optional

Example:

  argnum(opname2code('bless')) => 145
  145 = 0b10010001 => S S?

  first 4 bits 0001 => 1st arg is a Scalar,
  next 4 bits  1001 => (bit 8+1) 2nd arg is an optional Scalar

=item opclass (OP)

Returns the op class as number according to the following table:

    '0',  0,		# baseop
    '1',  1,		# unop
    '2',  2,		# binop
    '|',  3,		# logop
    '@',  4,		# listop
    '/',  5,		# pmop
    '$',  6,		# svop_or_padop
    '#',  7,		# padop
    '"',  8,		# pvop_or_svop
    '{',  9,		# loop
    ';',  10,		# cop
    '%',  11,		# baseop_or_unop
    '-',  12,		# filestatop
    '}',  13,		# loopexop

=item opflags (OP)

Returns op flags as number according to the following table:

    'm' =>   1,		# needs stack mark
    'f' =>   2,		# fold constants
    's' =>   4,		# always produces scalar
    't' =>   8,		# needs target scalar
    'T' =>   8 | 256,	# ... which may be lexical
    'i' =>  16,		# always produces integer
    'I' =>  32,		# has corresponding int op
    'd' =>  64,		# danger, unknown side effects
    'u' => 128,		# defaults to $_

plus not from F<opcode.pl>:

    'n' => 512,		# nothing on the stack, no args and return

These not yet:

    'S' => 1024 	# retval may be scalar
    'A' => 2048 	# retval may be array
    'V' => 4096 	# retval may be void
    'F' => 8192 	# fixed retval type, either S or A or V

=item opaliases (OP)

Returns the opcodes for the aliased opcode functions for the given OP, the ops
with the same ppaddr.

=item opname2code (OPNAME)

Does a reverse lookup in the opcodes list to get the opcode for the given
name.

=back

=head1 SEE ALSO

L<Opcode> -- The Perl CORE Opcode module for sets of Opcodes, used by L<Safe>.

L<Safe> -- Opcode and namespace limited execution compartments

=head1 AUTHOR

Reini Urban C<rurban@cpan.org> 2010

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab shiftwidth=4:
