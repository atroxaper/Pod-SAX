use v6;

use Test;

use Pod::Style::Carder;

plan 28;

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

{
	my $pod-string = qq:to[END];
		=begin pod
		=head1
		1

		2D<3>4
		=end pod
		END

	my $pod = get-pod($pod-string);
	my $instance;
	my $status;
	lives_ok {$instance = Comb.new}, 'create Comb';

	my @para =
		sub { True; } => {
			in => sub (:@draft, :$content) { push @draft, $content; True; }
		};
	my @format =
		sub (:$type where {$type eq 'D'}) { True; } => {
			in => sub (:@draft, :$content) { push @draft, 'D' ~ $content ~ 'D'; True; }
		};
	$instance.callbacks{Pod::Block::Para.^name} = @para;
	$instance.callbacks{Pod::FormattingCode.^name} = @format;

	lives_ok {$status = $instance.approach-to($pod)}, 'call callbacks without exceptions';
	ok $status == True, 'status is True';
	is $instance.draft.join('|'), '1|2|D3D|4', 'result array in right order';
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
	is %pod-attrs{'config'}.{'huge'}, 1, 'heading config has elem huge => 1';
}

{#= test basic functionality
	my $pod-string = qq:to/END/;
		=begin head1
		123
		=end head1
		END
	my $pod = get-pod($pod-string);

	my @head-calls =
		sub (:$level, :%config, :@content, :$instance) { return so .defined for $level, %config, @content, $instance; } => {
			start => sub (:@draft) {@draft.push('start of head'); True; },
			stop => sub (:@draft) {@draft.push('stop of head'); True; },
			in => sub (:@draft) {@draft.push('in of head'); True; }
		};

	my Comb $comb .= new();
	$comb.callbacks{Pod::Heading.^name} = @head-calls;

	$comb.approach-to($pod[0]);
	is $comb.draft.join('|'), 'start of head|stop of head', 'callback for start and stop of head';
}

{#= history support test
	my $pod-string = qq:to[END];
		=begin pod
		=head1
		1

		2D<3>4
		=end pod
		END

	my $pod = get-pod($pod-string);
	my Comb $comb .= new();
	my @heading =
		sub { True; } => {
			start => sub (:@draft, :$level) { push @draft, "<h$level>"; True; },
			stop => sub (:@draft, :$level) { push @draft, "</h$level>"; True; }
		};
	my @para =
		sub (:@history where {@history && @history[*-1] ~~ Pod::Heading}) { True; } => {
			in => sub (:@draft, :$content) { push @draft, "big para $content"; True; }
		},
		sub { True; } => {
			in => sub (:@draft, :$content) { push @draft, $content; True; }
		};
	my @format =
		sub (:$type where {$type eq 'D'}) { True; } => {
			in => sub (:@draft, :$content) { push @draft, 'D' ~ $content ~ 'D'; True; }
		};
	$comb.callbacks{Pod::Heading.^name} = @heading;
	$comb.callbacks{Pod::Block::Para.^name} = @para;
	$comb.callbacks{Pod::FormattingCode.^name} = @format;

	$comb.approach-to($pod);
	is $comb.draft.join('|'), '<h1>|big para 1|</h1>|2|D3D|4', "history works well";
}

{#= test storage and clear
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END

    my $pod = get-pod($pod-string);
    my Comb $comb .= new;
    my @para =
    	sub (:@history where {@history && @history[*-1] ~~ Pod::Block::Named && @history[*-1].name ~~ 'TITLE'}) { True; } => {
    		in => sub (:$content, :@draft, :%storage) { push @draft, $content; %storage{'TITLE'} = $content; True; }
    	};
	$comb.callbacks{Pod::Block::Para.^name} = @para;
	$comb.approach-to($pod);
	is $comb.draft.join, 'Synopsis 26 - Documentation', 'call for TITLE ok';
	is $comb.storage{'TITLE'}, 'Synopsis 26 - Documentation', 'storage works well';

	$comb.approach-to($pod);
	isnt $comb.draft.join, 'Synopsis 26 - Documentation', 'two calls in a row did different result';
	$comb.clear();
	$comb.approach-to($pod);
	is $comb.draft.join, 'Synopsis 26 - Documentation', 'two calls in a row with clear did the same result';
}

{#= test state
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END

	my $pod = get-pod($pod-string);
	my Comb $comb .= new;
	my @para =
		sub { True; } => {
			start => sub (:%state) { %state<foo> = 'bar'; True; },
			in => sub (:$content, :@draft, :%storage) { push @draft, $content; True; },
			stop => sub (:@draft, :%state) { push @draft, %state<foo>; True; }
		};
	my @named =
		sub (:$name where({$^name eq 'TITLE'})) { True; } => { # TODO why we need '^'
			start => sub (:%state) { %state<foo> = 'foobar'; True; },
			stop => sub (:@draft, :%state) { push @draft, %state<foo>; True; }
		};
	$comb.callbacks{Pod::Block::Para.^name} = @para;
	$comb.callbacks{Pod::Block::Named.^name} = @named;
	$comb.approach-to($pod);
	is $comb.draft.join('|'), 'Synopsis 26 - Documentation|bar|foobar', 'state works well';
}

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

{#= test anchor calling
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END
	my $pod = get-pod($pod-string);
	my Comb $comb .= new;
	my @para =
		sub { True; } => {
			start => sub (:@draft) { push @draft, SimpleAnchor.new(:template('<p><%=para1%></p>'), :priority(0)); True; },
			in => sub (:@draft) { push @draft, SimpleAnchor.new(:template('<p><%=para2%></p>'), :priority(0)); True; },
			stop => sub (:@draft) { push @draft, SimpleAnchor.new(:template('<p><%=para3%></p>'), :priority(0)); True; },
		};
	my @named =
		sub (:$name where({$^name eq 'TITLE'})) { True; } => { # TODO why we need '^'
			start => sub (:@draft) { push @draft, SimpleAnchor.new(:template('<title><%=TITLE%></title>'), :priority(0)); True; },
			stop => sub (:%storage) { %storage<para1> = 'p1'; %storage<para2> = 'p2';
				%storage<para3> = 'p3'; %storage<TITLE> = 'title'; %storage<foo> = 'bar'; }
		};
	$comb.callbacks{Pod::Block::Para.^name} = @para;
	$comb.callbacks{Pod::Block::Named.^name} = @named;
	$comb.approach-to($pod);
	is $comb.get-result, '<title>title</title><p>p1</p><p>p2</p><p>p3</p>',
		'result and anchors calling without priority works well';
}

{#= test selector's helpers
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END
	my $pod = get-pod($pod-string);
	my Comb $comb .= new;
	my @para =
		sub (:@history where {@history.&under-name('TITLE')}) { True; } => {
			start => sub (:@draft) { push @draft, 'under title'; True; }
		};
	my @named =
		sub (:@history where {@history.&under-type(Pod::Block::Named)}) { True; } => {
			start => sub (:@draft) { push @draft, 'under named'; True; }
		};
	$comb.callbacks{Pod::Block::Para.^name} = @para;
	$comb.callbacks{Pod::Block::Named.^name} = @named;

	$comb.approach-to($pod);
	is $comb.draft.join('|'), 'under named|under title', "selector's helpers works well"
}