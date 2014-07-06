use v6;

use Test;

use Pod::Goes::HTML;
use Pod::Nearby;

plan 1;

# Test by eyes #
my Nearer $nearer = make-nearer;
ok $nearer, 'make caller works well';
my $pod = get-pod slurp('../in.txt'.path);
$nearer.approach-to($pod);
say "draft is:\n{$nearer.get-result}\n" ~ '-' x 30;
my $out = open 'html-out.html', :w;
$out.say($nearer.get-result);
$out.close();