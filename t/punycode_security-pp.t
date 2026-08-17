use strict;
use utf8;
use warnings;

use Test::More;
use Net::IDN::Punycode::PP ();

use Test::NoWarnings;

our @decode_dies = (
  ["NMzZNlL6SU", qr/incomplete encoded code point/,
    "truncated label without a delimiter"],
  ["abc-td", qr/incomplete encoded code point/,
    "truncated label after base characters"],
  ["z", qr/incomplete encoded code point/,
    "single digit ending mid code point"],
);

plan tests => 1
  + 2 * (scalar @decode_dies);

foreach my $test (@decode_dies)
{
  my ($label, $message, $comment) = @{$test};

  is(eval { Net::IDN::Punycode::PP::decode_punycode($label) }, undef,
    $comment.' (decode_punycode dies)');
  like($@, $message, $comment.' (decode_punycode message)');
}
