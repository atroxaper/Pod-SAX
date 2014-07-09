use v6;

use Test;

use Pod::SAX::Anchors;

plan 6;

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
	is_deeply $anchor.storage, {a => 42, b => 43}, 'init-anchor works well';
}