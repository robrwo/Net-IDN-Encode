use strict;
use utf8;
use Test::Spelling;

add_stopwords(map { split /[ \r\n]+/ } <DATA>);
all_pod_files_spelling_ok();

__END__
ASCIIRules
AllowUnassigned
Bootstring
Claus Färber
IDN
IDNA
IDNs
IRIs
LDH
NFC
NFD
Nameprep
Punycode
Rothenberg
SRV
STD
Tatsuhiko Miyagawa
ToASCII
ToUnicode
TransitionalProcessing
UNICODE
UTS
UseSTD
ZWJ
ZWNJ
diacritics
fullwidth
halfwidth
ideographic
internationalized
internationalizing
interoperable
normalization
programmes
ss
