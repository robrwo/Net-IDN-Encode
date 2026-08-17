use strict;
use warnings;

use Test::More;
use Net::IDN::Punycode ();
use Net::IDN::Punycode::PP ();

BEGIN {
  plan skip_all => 'no XS version' if eval {
    \&Net::IDN::Punycode::decode_punycode ==
    \&Net::IDN::Punycode::PP::decode_punycode; }
}

use Test::NoWarnings;

our @large = (
  ["a" x 200000, "a label of single-digit code points"],
);

plan tests => 1
  + 1 * (scalar @large);

foreach my $test (@large)
{
  my ($label, $comment) = @{$test};

  SKIP: {
    my $pid = fork;
    skip 'cannot fork', 1 if !defined $pid;

    if (!$pid) {
      close STDERR;
      alarm 10;
      eval { Net::IDN::Punycode::decode_punycode($label) };
      exit 0;
    }

    waitpid($pid, 0);
    is($? & 127, 0, $comment.' (decode_punycode keeps up)');
  }
}
