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

our @decode_dies = (
  ["a-99999999999999999999", qr/exceeds punycode limit/,
    "digit weight overflows"],
  ["a-8s902716a", qr/exceeds punycode limit/,
    "delta accumulator overflows"],
  ["a-kk503321e", qr/exceeds punycode limit/,
    "delta accumulator overflows further"],
);

our @decode_roundtrips = (
  [chr(0x10FFFF) x 125, "decoding outgrows the output buffer"],
);

plan tests => 1
  + 2 * (scalar @encode_dies)
  + 3 * (scalar @decode_dies)
  + 1 * (scalar @decode_roundtrips);

foreach my $test (@encode_dies)
{
  my ($input, $message, $comment) = @{$test};

  is(eval { Net::IDN::Punycode::encode_punycode($input) }, undef,
    $comment.' (encode_punycode dies)');
  like($@, $message, $comment.' (encode_punycode message)');
}

foreach my $test (@decode_dies)
{
  my ($label, $message, $comment) = @{$test};

  is(eval { Net::IDN::Punycode::decode_punycode($label) }, undef,
    $comment.' (decode_punycode dies)');
  like($@, $message, $comment.' (decode_punycode message)');

  is(eval { Net::IDN::Punycode::PP::decode_punycode($label) }, undef,
    $comment.' (PP decode_punycode dies)');
}

foreach my $test (@decode_roundtrips)
{
  my ($input, $comment) = @{$test};

  my $label = Net::IDN::Punycode::PP::encode_punycode($input);
  is(Net::IDN::Punycode::decode_punycode($label), $input,
    $comment.' (decode_punycode round-trips)');
}
