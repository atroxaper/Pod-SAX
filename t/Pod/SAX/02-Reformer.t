use v6;

use Test;
use lib 'lib';
use Pod::SAX::Common;
use Pod::SAX::Anchors;
use Pod::SAX::Reformer;

plan 19;

{
	my $pod-string = qq:to[END];
		=begin pod
		=head1
		1

		2D<3>4
		=end pod
		END

	my $pod = get-pod($pod-string);
	my $reformer;
	my $status;
	lives-ok {$reformer = Reformer.new}, 'create Reformer';

	my @para =
		:() => {
			in => { append $:contents; }
		};
	my @format =
		:(:$type where 'D') => {
			in => { append 'D' ~ $:contents ~ 'D'; }
		};
	$reformer.callbacks{Pod::Block::Para.^name} = @para;
	$reformer.callbacks{Pod::FormattingCode.^name} = @format;

	lives-ok {$status = $reformer.reform($pod)}, 'call callbacks without exceptions';
	ok $status == True, 'status is True';
	is $reformer.draft.join('|'), '1|2|D3D|4', 'result array in right order';
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
	my %pod-attrs = Reformer.get-attributes($pod[0]);

	is %pod-attrs.elems, 3, 'pod-info has right size';
	is %pod-attrs{'level'}, 1, 'heading level equals 1';
	is %pod-attrs{'config'}.elems, 0, 'heading config is empty';
	is %pod-attrs{'content'}.elems, 1, 'heading content has one elem';

	%pod-attrs = Reformer.get-attributes($pod[1]);

	is %pod-attrs.elems, 3, 'pod-info has right size';
	is %pod-attrs{'config'}.elems, 1, 'heading config has one elem';
	is %pod-attrs{'config'}.{'huge'}, True, 'heading config has elem huge => 1';
}

{#= test basic functionality
	my $pod-string = qq:to/END/;
		=begin head1
		123
		=end head1
		END
	my $pod = get-pod($pod-string);

	my @head-calls =
		#| There is example that we can use as Signature, as Sub like selector of callback. #
		sub (:$level, :%config, :@contents) {
			return all($level, %config, @contents).defined;
		} => {
			start => { append 'start of head' },
			stop  => { append 'stop of head'  },
			in    => { append 'in of head'    }
		};

	my Reformer $reformer .= new();
	$reformer.callbacks{Pod::Heading.^name} = @head-calls;

	$reformer.reform($pod[0]);
	is $reformer.draft.join('|'), 'start of head|stop of head', 'callback for start and stop of head';
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
	my Reformer $reformer .= new();
	my @heading =
		:() => {
			start => { append "<h$:level>"  },
			stop  => { append "</h$:level>" }
		};
	my @para =
		:(:@history where {$_ && $_[*-1] ~~ Pod::Heading}) => {
			in => { append "big para $:contents" }
		},
		:() => {
			in => { append $:contents }
		};
	my @format =
		:(:$type where 'D') => {
			in => { append 'D' ~ $:contents ~ 'D' }
		};
	$reformer.callbacks{Pod::Heading.^name} = @heading;
	$reformer.callbacks{Pod::Block::Para.^name} = @para;
	$reformer.callbacks{Pod::FormattingCode.^name} = @format;

	$reformer.reform($pod);
	is $reformer.draft.join('|'), '<h1>|big para 1|</h1>|2|D3D|4', "history works well";
}

{#= test storage and clear
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END

    my $pod = get-pod($pod-string);
    my Reformer $reformer .= new;
    my @para =
    	:(:@history where {$_ && $_[*-1] ~~ Pod::Block::Named && $_[*-1].name ~~ 'TITLE'}) => {
    		in => { append $:contents; %:storage{'TITLE'} = $contents }
    	};
	$reformer.callbacks{Pod::Block::Para.^name} = @para;
	$reformer.reform($pod);
	is $reformer.draft.join, 'Synopsis 26 - Documentation', 'call for TITLE ok';
	is $reformer.storage{'TITLE'}, 'Synopsis 26 - Documentation', 'storage works well';

	$reformer.reform($pod);
	isnt $reformer.draft.join, 'Synopsis 26 - Documentation', 'two calls in a row did different result';
	$reformer.clear();
	$reformer.reform($pod);
	is $reformer.draft.join, 'Synopsis 26 - Documentation', 'two calls in a row with clear did the same result';
}

{#= test state
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END

	my $pod = get-pod($pod-string);
	my Reformer $reformer .= new;
	my @para =
		:() => {
			start => { %:state<foo> = 'bar' },
			in    => { append $:contents },
			stop  => { append %:state<foo> }
		};
	my @named =
		:(:$name where 'TITLE') => {
			start => { %:state<foo> = 'foobar' },
			stop  => { append %:state<foo> }
		};
	$reformer.callbacks{Pod::Block::Para.^name} = @para;
	$reformer.callbacks{Pod::Block::Named.^name} = @named;
	$reformer.reform($pod);
	is $reformer.draft.join('|'), 'Synopsis 26 - Documentation|bar|foobar', 'state works well';
}

{#= test anchor calling
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END
	my $pod = get-pod($pod-string);
	my Reformer $reformer .= new;
	my @para =
		:() => {
			start => { append SimpleAnchor.new(:template('<p><%=para1%></p>'), :priority(0)) },
			in    => { append SimpleAnchor.new(:template('<p><%=para2%></p>'), :priority(0)) },
			stop  => { append SimpleAnchor.new(:template('<p><%=para3%></p>'), :priority(0)) },
		};
	my @named =
		:(:$name where 'TITLE') => { # TODO why we need '^'
			start => { append SimpleAnchor.new(:template('<title><%=TITLE%></title>'), :priority(0)) },
			stop  => { %:storage<para1> = 'p1'; %storage<para2> = 'p2';
				%storage<para3> = 'p3'; %storage<TITLE> = 'title'; %storage<foo> = 'bar'; }
		};
	$reformer.callbacks{Pod::Block::Para.^name} = @para;
	$reformer.callbacks{Pod::Block::Named.^name} = @named;
	$reformer.reform($pod);
	is $reformer.get-result, '<title>title</title><p>p1</p><p>p2</p><p>p3</p>',
		'result and anchors calling without priority works well';
}
