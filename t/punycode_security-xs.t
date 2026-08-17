use strict;
use utf8;
use warnings;

BEGIN {
  binmode STDOUT, ':utf8';
  binmode STDERR, ':utf8';
}

use Test::More;
use Net::IDN::Punycode ();
use Net::IDN::Punycode::PP ();

BEGIN {
  plan skip_all => 'no XS version' if eval {
    \&Net::IDN::Punycode::decode_punycode ==
    \&Net::IDN::Punycode::PP::decode_punycode; }
}

use Test::NoWarnings;

our @encode_dies = (
  ["a".chr(0xFFFFFFFF), qr/exceeds punycode limit/,
    "encoding overflows the delta accumulator"],
);

plan tests => 1 + 2 * (scalar @encode_dies);

foreach my $test (@encode_dies)
{
  my ($input, $message, $comment) = @{$test};

  is(eval { Net::IDN::Punycode::encode_punycode($input) }, undef,
    $comment.' (encode_punycode dies)');
  like($@, $message, $comment.' (encode_punycode message)');
}
