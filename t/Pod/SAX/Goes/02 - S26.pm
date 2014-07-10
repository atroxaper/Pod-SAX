use v6;

use Test;

use Pod::SAX::Goes::HTML;
use Pod::SAX::Reformer;
use Pod::SAX::Common;

plan 1;

# Test by eyes #
my Reformer $reformer = make-reformer;
ok $reformer, 'make caller works well';
my $pod = get-pod slurp('../../../../in.txt'.path);
$reformer.reform($pod);
say "draft is:\n{$reformer.get-result}\n" ~ '-' x 30;
my $out = open '../../../../index.html', :w;
$out.say($reformer.get-result);
$out.close();