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
  [("a" x 4368).chr(983183), qr/exceeds punycode limit/,
    "the skipped basic code points overflow the delta accumulator"],
);

our @decode_dies = (
  ["\x80", qr/non-base character/,
    "a byte outside the basic code points"],
  ["a-99999999999999999999", qr/exceeds punycode limit/,
    "digit weight overflows"],
  ["a-8s902716a", qr/invalid code point/,
    "decodes to the top of the signed 32 bit range"],
  ["a-kk503321e", qr/exceeds punycode limit/,
    "delta accumulator overflows"],
  ["a-j023p", qr/invalid code point/,
    "decodes just above U+10FFFF"],
  ["a-8y735a", qr/invalid code point/,
    "decodes far above U+10FFFF"],
);

our @decode_roundtrips = (
  [chr(0x10FFFF) x 125, "decoding outgrows the output buffer"],
);

our @agree = (
  [("a" x 1926).chr(0x10FFFF), "delta just below the RFC 3492 limit"],
  [("a" x 1927).chr(0x10FFFF), "delta above a signed 32 bit limit"],
);

our @stringifies = (
  [[1 .. 50], "an array reference"],
  [sub { 1 }, "a code reference"],
  [\"scalar", "a scalar reference"],
);

our @encode_malformed = (
  ["abc\xE2\x82", "a truncated UTF-8 sequence"],
  ["\xE2\x82abc", "a truncated UTF-8 sequence at the start"],
  ["abc\xFF", "a byte which starts no UTF-8 sequence"],
);

plan tests => 1
  + 1 * (scalar @encode_malformed)
  + 2 * (scalar @encode_dies)
  + 3 * (scalar @decode_dies)
  + 1 * (scalar @decode_roundtrips)
  + 2 * (scalar @agree)
  + 1 * (scalar @stringifies);

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

foreach my $test (@agree)
{
  my ($input, $comment) = @{$test};

  my $label = eval { Net::IDN::Punycode::encode_punycode($input) };
  is($label, Net::IDN::Punycode::PP::encode_punycode($input),
    $comment.' (encode_punycode matches PP)');
  is(eval { Net::IDN::Punycode::decode_punycode($label) }, $input,
    $comment.' (decode_punycode round-trips)');
}

foreach my $test (@stringifies)
{
  my ($input, $comment) = @{$test};

  my $string = "$input";
  eval { Net::IDN::Punycode::decode_punycode($input) };
  my $from_ref = (split / at /, $@)[0];
  eval { Net::IDN::Punycode::decode_punycode($string) };
  my $from_string = (split / at /, $@)[0];

  is($from_ref, $from_string,
    $comment.' (decode_punycode reads only the stringified value)');
}

foreach my $test (@encode_malformed)
{
  my ($bytes, $comment) = @{$test};

  SKIP: {
    my $pid = fork;
    skip 'cannot fork', 1 if !defined $pid;

    if (!$pid) {
      close STDERR;
      require Encode;
      Encode::_utf8_on($bytes);
      alarm 10;
      eval { Net::IDN::Punycode::encode_punycode($bytes) };
      exit 0;
    }

    waitpid($pid, 0);
    is($? & 127, 0, $comment.' (encode_punycode terminates)');
  }
}
