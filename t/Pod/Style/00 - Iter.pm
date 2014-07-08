use v6;

use Test;
use Pod::Nearby;

use Pod::Style::Iter;

plan 7;

my Pod::Style::Iter::Start $start .= new(:content('cont'));
is +$start.content, 1, "Start's content has one element";
is $start.content[0], 'cont', "Start's content has good element";

ok Pod::Style::Iter::has-content($start), "Start has content";
nok Pod::Style::Iter::has-content("String"), "String doesn't have content";

my $pod-string = qq:to[END];
	=begin pod
	=head1
	1

	2D<3>4
	=end pod
	END
my $pod = get-pod($pod-string);
my Iterator $iter .= new();
$iter.init($pod);
my (@pair, @delta, @contents, @items) = ();
while (@pair = $iter.get-next).elems > 1 {
	@delta.push(@pair[1]);
	@items.push(@pair[0].^name) if @pair[1] == 1;
	@contents.push(@pair[0]) if @pair[1] == 0;
}
is @delta.join('|'), '1|1|1|0|-1|-1|1|0|1|0|-1|0|-1|-1', 'delta';
is @items.join('|'), 'Pod::Block::Named|Pod::Heading|Pod::Block::Para|Pod::Block::Para|Pod::FormattingCode', 'items';
is @contents.join('|'), '1|2|3|4', 'contents';
