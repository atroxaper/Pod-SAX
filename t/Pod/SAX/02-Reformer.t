use v6;

use Test;
use lib 'lib';
use Saxopod::Reformator;
use Saxopod::Reformator::Common;
use Saxopod::Reformator::Anchors;
use Saxopod::Reformator::Extension;

plan 23;

{
	my $pod-string = qq:to[END];
		=begin pod
		=head1
		1

		2D<3>4
		=end pod
		END

	my $pod = get-pod($pod-string);
	my $reformator;
	my $status;
	lives-ok {$reformator = Reformator.new}, 'create Reformer';

	my @para =
		:() => {
			in => { append $:contents; }
		};
	my @format =
		:(:$type where 'D') => {
			in => { append 'D' ~ $:contents ~ 'D'; }
		};
	$reformator.callbacks{Pod::Block::Para.^name} = @para;
	$reformator.callbacks{Pod::FormattingCode.^name} = @format;

	lives-ok {$status = $reformator.reform($pod)}, 'call callbacks without exceptions';
	ok $status == True, 'status is True';
	is $reformator.draft.join('|'), '1|2|D3D|4', 'result array in right order';
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
	my %pod-attrs = Reformator.get-attributes($pod[0]);

	is %pod-attrs.elems, 3, 'pod-info has right size';
	is %pod-attrs{'level'}, 1, 'heading level equals 1';
	is %pod-attrs{'config'}.elems, 0, 'heading config is empty';
	is %pod-attrs{'content'}.elems, 1, 'heading content has one elem';

	%pod-attrs = Reformator.get-attributes($pod[1]);

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

	my Reformator $reformator .= new();
	$reformator.callbacks{Pod::Heading.^name} = @head-calls;

	$reformator.reform($pod[0]);
	is $reformator.draft.join('|'), 'start of head|stop of head', 'callback for start and stop of head';
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
	my Reformator $reformator .= new();
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
	$reformator.callbacks{Pod::Heading.^name} = @heading;
	$reformator.callbacks{Pod::Block::Para.^name} = @para;
	$reformator.callbacks{Pod::FormattingCode.^name} = @format;

	$reformator.reform($pod);
	is $reformator.draft.join('|'), '<h1>|big para 1|</h1>|2|D3D|4', "history works well";
}

{#= test storage and clear
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END

    my $pod = get-pod($pod-string);
    my Reformator $reformator .= new;
    my @para =
    	:(:@history where {$_ && $_[*-1] ~~ Pod::Block::Named && $_[*-1].name ~~ 'TITLE'}) => {
    		in => { append $:contents; %:storage{'TITLE'} = $contents }
    	};
	$reformator.callbacks{Pod::Block::Para.^name} = @para;
	$reformator.reform($pod);
	is $reformator.draft.join, 'Synopsis 26 - Documentation', 'call for TITLE ok';
	is $reformator.storage{'TITLE'}, 'Synopsis 26 - Documentation', 'storage works well';

	$reformator.reform($pod);
	isnt $reformator.draft.join, 'Synopsis 26 - Documentation', 'two calls in a row did different result';
	$reformator.clear();
	$reformator.reform($pod);
	is $reformator.draft.join, 'Synopsis 26 - Documentation', 'two calls in a row with clear did the same result';
}

{#= test state
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END

	my $pod = get-pod($pod-string);
	my Reformator $reformator .= new;
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
	$reformator.callbacks{Pod::Block::Para.^name} = @para;
	$reformator.callbacks{Pod::Block::Named.^name} = @named;
	$reformator.reform($pod);
	is $reformator.draft.join('|'), 'Synopsis 26 - Documentation|bar|foobar', 'state works well';
}

{#= test anchor calling
	my $pod-string = qq:to[END];
		=begin pod

		=TITLE
		Synopsis 26 - Documentation

		=end pod
		END
	my $pod = get-pod($pod-string);
	my Reformator $reformator .= new;
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
	$reformator.callbacks{Pod::Block::Para.^name} = @para;
	$reformator.callbacks{Pod::Block::Named.^name} = @named;
	$reformator.reform($pod);
	is $reformator.get-result, '<title>title</title><p>p1</p><p>p2</p><p>p3</p>',
		'result and anchors calling without priority works well';
}

{#= test for extensions

  my $pod-string = qq:to[END];
      =begin pod

      =TITLE
      Synopsis 26 - Documentation

      Just paragraph;

      =comment comment;

      =end pod
      END
  my $pod = get-pod($pod-string);
  say $pod;

  my class TestExt does Extension {
    method produce-args(Pod::Block $pod --> List) {
      my @contents := $pod.contents;
      my @result[@contents.elems];
      for @contents.kv -> $i, $content {
        @result[$i] = %('ext-named' => 1) if $content ~~ Pod::Block::Named;
        @result[$i] = %('ext-para' => 2, 'ext-para-more' => 3) if $content ~~ Pod::Block::Para;
      }
      return @result;
    }
  }

  my Reformator $reformator .= new(extensions => (TestExt.new));
  my ($para1, $para2, $named1, $all) = False, False, False, False;
  my @para =
    :(:$ext-para where 2, :$ext-para-more where 3) => {
      start => { ($para1, $para2) = True, True },
    },
    :(:$ext-named where 1, :$ext-para where 2, :$ext-para-more where 3) => {
      start => { $all = True },
    };
  my @named =
    :(:$name where 'TITLE', :$ext-named where 1) => {\
      start => { $named1 = True },
    };
  $reformator.callbacks{Pod::Block::Para.^name} = @para;
  $reformator.callbacks{Pod::Block::Named.^name} = @named;
  $reformator.reform($pod);

  ok $para1, 'callback with arg from extension';
  ok $para2, 'callback with two args from extension';
  ok $named1, 'callback with other arg from extension';
  nok $all, 'args from extension do not mixes';
}
