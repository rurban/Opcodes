#!./perl -w

$|=1;

BEGIN {
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bOpcode\b/ && $Config{'osname'} ne 'VMS') {
        print "1..0\n";
        exit 0;
    }
}

use Opcode qw(
	opcodes opdesc opname ppaddr check opargs opaliases
        opmask verify_opset opset opset_to_ops opset_to_hex
        invert_opset opmask_add full_opset empty_opset define_optag
);

use strict;

my $t = 1;
my $last_test; # initalised at end
print "1..$last_test\n";

my($s1, $s2, $s3);
my(@o1, @o2, @o3);

# --- opset_to_ops and opset

my @empty_l = opset_to_ops(empty_opset);
print @empty_l == 0 ?   "ok $t\n" : "not ok $t\n"; $t++;

my @full_l1  = opset_to_ops(full_opset);
print @full_l1 == opcodes() ? "ok $t\n" : "not ok $t\n"; $t++;
my @full_l2 = map { $_->[1] } opcodes(); # names only
print "@full_l1" eq "@full_l2" ? "ok $t\n" : "not ok $t\n"; $t++;

@empty_l = opset_to_ops(opset(':none'));
print @empty_l == 0 ?   "ok $t\n" : "not ok $t\n"; $t++;

my @full_l3 = opset_to_ops(opset(':all'));
print  @full_l1  ==  @full_l3  ? "ok $t\n" : "not ok $t\n"; $t++;
print "@full_l1" eq "@full_l3" ? "ok $t\n" : "not ok $t\n"; $t++;

die $t unless $t == 7;
$s1 = opset(      'padsv');
$s2 = opset($s1,  'padav');
$s3 = opset($s2, '!padav');
print $s1 eq $s2 ? "not ok $t\n" : "ok $t\n"; ++$t;
print $s1 eq $s3 ? "ok $t\n" : "not ok $t\n"; ++$t;

# --- define_optag

print eval { opset(':_tst_') } ? "not ok $t\n" : "ok $t\n"; ++$t;
define_optag(":_tst_", opset(qw(padsv padav padhv)));
print eval { opset(':_tst_') } ? "ok $t\n" : "not ok $t\n"; ++$t;

# --- opdesc and opcodes

die $t unless $t == 11;
print opdesc("gv") eq "glob value" ? "ok $t\n" : "not ok $t\n"; $t++;
my @desc = opdesc(':_tst_','stub');
print "@desc" eq "private variable private array private hash stub"
				    ? "ok $t\n" : "not ok $t\n#@desc\n"; $t++;
@full_l1 = opcodes();
print @full_l1 ? "ok $t\n" : "not ok $t\n"; $t++;
my $op0 = $full_l1[0];
print @$op0 == 5  ? "ok $t\n" : "not ok $t - [5]\n"; $t++;
print opname(0) eq 'null' ? "ok $t\n" : "not ok $t - opname\n"; $t++;
# fails for <5.8.9
if (opaliases(0)) {
  print ((ppaddr(0) and ppaddr(0) eq ppaddr(2)) ? "ok $t\n" : "not ok $t - ppaddr\n"); $t++;
} else {
  print "ok $t #skip - no opaliases(0) $]\n"; $t++;
}
print ((check(0) and check(0) eq check(1)) ? "ok $t - check\n" : "not ok $t - check\n"); $t++;
print opargs(0) == 0 ? "ok $t - opargs\n" : "not ok $t - opargs\n"; $t++;
my @al = opaliases(0); #scalar regcmaybe lineseq scope
if (@al) {
  print ((@al == 4 and $al[0] == 2) ? "ok $t - opaliases\n" : "not ok $t - opaliases\n"); $t++;
} else {
  # fails for <5.8.9
  print "ok $t #skip - no opaliases(0) $]\n"; $t++;
}
# find bless at 23
my $bless;
for (0..@full_l1) { if (opname($_) eq 'bless') { $bless = $_; last } }
print $bless == Opcode::opname2code('bless') ? "ok $t - opname2code\n" : "not ok $t - opname2code\n"; $t++;
print Opcode::opclass($bless) == 4 ? "ok $t\n" : "not ok $t - bless: listop 4 @\n"; $t++;
print Opcode::opflags($bless) == 4 ? "ok $t\n" : "not ok $t - bless: flags 4 s\n"; $t++;
print Opcode::argnum($bless) == 145 ? "ok $t\n" : "not ok $t - bless: S S? 145\n"; $t++;

# --- invert_opset

$s1 = opset(qw(fileno padsv padav));
@o2 = opset_to_ops(invert_opset($s1));
print @o2 == opcodes-3 ? "ok $t\n" : "not ok $t\n"; $t++;

# --- opmask

die $t unless $t == 25;
print opmask() eq empty_opset() ? "ok $t\n" : "not ok $t\n"; $t++;	# work
print length opmask() == int((opcodes()+7)/8) ? "ok $t\n" : "not ok $t\n"; $t++;

# --- verify_opset

print verify_opset($s1) && !verify_opset(42) ? "ok $t\n":"not ok $t\n"; $t++;

# --- opmask_add

opmask_add(opset(qw(fileno)));	# add to global op_mask
print eval 'fileno STDOUT' ? "not ok $t\n" : "ok $t\n";	$t++; # fail
if ($] < 5.007) { # different trap message
  print $@ =~ /fileno trapped/ ? "ok $t\n" : "not ok $t\n# $@\n"; $t++;
} else {
  print $@ =~ /'fileno' trapped/ ? "ok $t\n" : "not ok $t\n# $@\n"; $t++;
}
# --- check use of bit vector ops on opsets

$s1 = opset('padsv');
$s2 = opset('padav');
$s3 = opset('padsv', 'padav', 'padhv');

# Non-negated
print (($s1 | $s2) eq opset($s1,$s2) ? "ok $t\n":"not ok $t\n"); $t++;
print (($s2 & $s3) eq opset($s2)     ? "ok $t\n":"not ok $t\n"); $t++;
print (($s2 ^ $s3) eq opset('padsv','padhv') ? "ok $t\n":"not ok $t\n"); $t++;

# Negated, e.g., with possible extra bits in last byte beyond last op bit.
# The extra bits mean we can't just say ~mask eq invert_opset(mask).

@o1 = opset_to_ops(           ~ $s3);
@o2 = opset_to_ops(invert_opset $s3);
print "@o1" eq "@o2" ? "ok $t\n":"not ok $t\n"; $t++;

# --- finally, check some opname assertions

foreach(@full_l2) { die "bad opname: $_" if /\W/ or /^\d/ }

print "ok $last_test\n";
BEGIN { $last_test = 34 }
