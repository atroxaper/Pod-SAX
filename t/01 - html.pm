use v6;

use Test;

use Pod::Goes::HTML;
use Pod::Callback;

plan 1;

my Caller $caller = make-caller;
ok $caller, 'make caller works well';
my $pod = get-pod slurp('../in.txt'.path);
$caller.call-for($pod);
say "draft is:\n{$caller.get-result}\n" ~ '-' x 30;