use v6;

use Test;

use Pod::To::Callback;

plan 16;

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
	lives_ok {$instance = Caller.new}, 'create Caller';

	my @para =
		sub { return True; } => {
			in => sub (:@draft, :$content) { push @draft, $content; return True; }
		};
	my @format =
		sub (:$type where {$type eq 'D'}) { return True; } => {
			in => sub (:@draft, :$content) { push @draft, $content; return True; }
		};
	$instance.callbacks{Pod::Block::Para.^name} = @para;
	$instance.callbacks{Pod::FormattingCode.^name} = @format;

	lives_ok {$status = $instance.call-for($pod)}, 'call callbacks without exceptions';
	ok $status == True, 'status is True';
	is $instance.draft.join('|'), '1|2|3|4', 'result array in right order';
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
		sub (:$level, :%config, :@content, :$instance) { return so .defined for $level, %config, @content, $instance;} => {
			start => sub (:@draft) {@draft.push('start of head'); return True; },
			stop => sub (:@draft) {@draft.push('stop of head'); return True; },
			in => sub (:@draft) {@draft.push('in of head'); return True; }
		};

	my Caller $caller .= new();
	$caller.callbacks{Pod::Heading.^name} = @head-calls;

	$caller.call-for($pod[0]);
	is $caller.draft.join('|'), 'start of head|stop of head', 'callback for start and stop of head';
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
	my Caller $instance .= new();
	my @heading =
		sub { return True; } => {
			start => sub (:@draft, :$level) { push @draft, "<h$level>"; return True; },
			stop => sub (:@draft, :$level) { push @draft, "</h$level>"; return True; }
		};
	my @para =
		sub (:@history where {@history && @history[*-1] ~~ Pod::Heading}) { return True; } => {
			in => sub (:@draft, :$content) { push @draft, "big para $content"; return True; }
		},
		sub { return True; } => {
			in => sub (:@draft, :$content) { push @draft, $content; return True; }
		};
	my @format =
		sub (:$type where {$type eq 'D'}) { return True; } => {
			in => sub (:@draft, :$content) { push @draft, $content; return True; }
		};
	$instance.callbacks{Pod::Heading.^name} = @heading;
	$instance.callbacks{Pod::Block::Para.^name} = @para;
	$instance.callbacks{Pod::FormattingCode.^name} = @format;

	$instance.call-for($pod);
	is $instance.draft.join('|'), '<h1>|big para 1|</h1>|2|3|4', "history works well";
}
