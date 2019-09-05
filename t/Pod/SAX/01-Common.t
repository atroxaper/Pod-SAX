use v6;

use Test;
use lib 'lib';
use Saxopod::Reformator;
use Saxopod::Reformator::Common;

plan 25;

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
	lives-ok {$pod = get-pod($pod-string)}, 'parse pod without exceptions';
	isa-ok $pod, Array, 'parse pod is adequate';
	isa-ok $pod[0], Pod::Block::Named, 'parse pod is more adequate then before';
}

{#= test selector's helpers
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END
	my $pod = get-pod($pod-string);
	my Reformator $reformator .= new;
	my @para =
		:(:@history where *.&under-name('TITLE')) => {
			start => { append 'under title'; True; }
		};
	my @named =
		:(:@history where *.&under-type(Pod::Block::Named)) => {
			start => { append 'under named'; True; }
		};
	$reformator.callbacks{Pod::Block::Para.^name} = @para;
	$reformator.callbacks{Pod::Block::Named.^name} = @named;

	$reformator.reform($pod);
	is $reformator.draft.join('|'), 'under named|under title', "selector's helpers works well"
}

{#= grammar MetaL test
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

{#= get-attributes testing
	my $pod-string = qq:to/END/;
		=begin head1
		123
		=end head1
		=begin head1 :huge
		456
		=end head1
		END
	my $pod = get-pod($pod-string);
	my %pod-attrs = get-attributes($pod[0]);

	is %pod-attrs.elems, 3, 'pod-info has right size';
	is %pod-attrs{'level'}, 1, 'heading level equals 1';
	is %pod-attrs{'config'}.elems, 0, 'heading config is empty';
	is %pod-attrs{'content'}.elems, 1, 'heading content has one elem';

	%pod-attrs = get-attributes($pod[1]);

	is %pod-attrs.elems, 3, 'pod-info has right size';
	is %pod-attrs{'config'}.elems, 1, 'heading config has one elem';
	is %pod-attrs{'config'}.{'huge'}, True, 'heading config has elem huge => 1';
}
