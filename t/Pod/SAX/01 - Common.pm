use v6;

use Test;
use Pod::SAX::Reformer;

use Pod::SAX::Common;

plan 18;

{#= simple test of parsing a string to Pod
	my $pod-string = qq:to[END];
		=begin pod

		=head1
		Pod

		s an easy-to-use D<Pod> is an easy-to-use markup language with a simple, consistent
		underlying document object mode

		=end pod
		END

	my $pod = 'fake';
	lives_ok {$pod = get-pod($pod-string)}, 'parse pod without exceptions';
	isa_ok $pod, Array, 'parse pod is adequate';
	isa_ok $pod[0], Pod::Block::Named, 'parse pod is more adequate then before';
}

{#= test selector's helpers
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END
	my $pod = get-pod($pod-string);
	my Reformer $reformer .= new;
	my @para =
		sub (:@history where {@history.&under-name('TITLE')}) { True; } => {
			start => sub (:@draft) { push @draft, 'under title'; True; }
		};
	my @named =
		sub (:@history where {@history.&under-type(Pod::Block::Named)}) { True; } => {
			start => sub (:@draft) { push @draft, 'under named'; True; }
		};
	$reformer.callbacks{Pod::Block::Para.^name} = @para;
	$reformer.callbacks{Pod::Block::Named.^name} = @named;

	$reformer.reform($pod);
	is $reformer.draft.join('|'), 'under named|under title', "selector's helpers works well"
}

{#| grammar MetaL test
	my $match = MetaL.parse('http://google.com#boom');
	is $match<scheme><type>, 'http', 'scheme found';
	ok $match<extern><from-root>.from != $match<extern><from-root>.to, 'from root';
	is $match<extern><path>, 'google.com', 'path found';
	is $match<intern>, '#boom', 'intern found';

	$match = MetaL.parse('doc:perldata');
	is $match<scheme><type>, 'doc', 'scheme doc';
	is $match<extern><path>, 'perldata', 'path perldata';
	nok $match<extern><from-root>.from != $match<extern><from-root>.to, 'without root';
	nok $match<intern>, 'without intern';

	$match = MetaL.parse('#doc');
	is $match<intern>, '#doc', 'only intern';
	nok $match<extern>, 'without extern';
	nok $match<scheme>, 'without scheme';

	$match = MetaL.parse('link');
	is $match<extern>, 'link', 'only extern';
	nok $match<scheme>, 'without scheme';
	nok $match<intern>, 'without intern';
}