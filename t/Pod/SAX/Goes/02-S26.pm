use v6;

use Test;

use Saxopod::Format::Html::HTML;
use Saxopod::Reformator;
use Saxopod::Reformator::Common;

plan 1;

# Test by eyes #
my Reformator $reformator = make-reformer;
ok $reformator, 'make caller works well';
my $pod = get-pod slurp('../../../../index.txt'.path);
$reformator.reform($pod);
my $result = $reformator.get-result;
say "draft is:\n{$result}\n" ~ '-' x 30;
my $out = open '../../../../index.html', :w;
$out.say($result);
$out.close();