use v6;

use Test;
use lib 'lib';
use Saxopod::Reformator::Anchors;

plan 9;

{#= test SimpeleAnchor
	my SimpleAnchor $anchor .= new(:template('<title><%=title%></title>'), :storage({}));
	nok $anchor.prepare(), 'prepare of anchor returns false';
	$anchor.storage = title => 'this is test title';
	ok $anchor.prepare(), 'prepare of anchor returns true';
	is $anchor, '<title>this is test title</title>', 'anchor works well';
}

{#= test init-anchor sub
	my SimpleAnchor $anchor .= new(:template('<title><%=title%></title>'));
	nok $anchor.storage, 'anchor storage is undefined yet';
	init-anchor($anchor, {draft => (1, 2, 3), storage => {a => 42, b => 43}});
	ok $anchor.storage, 'anchor storage is defined now';
	is-deeply $anchor.storage, {a => 42, b => 43}, 'init-anchor works well';
}

{#| test CallbackAnchor
	sub test(:%storage, :%custom) {
		my $search = %custom<search>;
		my $found = %storage{$search};
		if ($found) {
			return True, $found;
		}
		return False, '';
	}
	my CallbackAnchor $anchor .= new(:callback(&test), :custom({search => 'foo'}), :storage({foo => 'bar'}));
	nok $anchor.prepared, "anchor isn't prepared";
	ok $anchor.prepare, 'anchor prepared';
	is $anchor, 'bar', 'anchor works well';
}