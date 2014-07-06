use v6;

use Test;

use Pod::Goes::HTML;
use Pod::Nearby;

plan 3;

sub rm-n($str) {
	return $str.subst(/\n/, '', :g);
}

sub get-test-result(Str $source --> Str) {
	my Nearer $nearer = make-nearer;
	my $pod = get-pod($source);
	$nearer.approach-to($pod);
	return $nearer.get-result.&rm-n;
}

{# start and end of HTML file
	my $pod-str = qq:to[END];
		=begin pod

		=TITLE
		This Title

		=end pod
		END
	is get-test-result($pod-str),
		q[<!doctype html><html><head>] ~
		q[<title>This Title</title>] ~
		q[</head><body class="pod" id="___top">] ~
		q[<h1>This Title</h1>] ~
		q[</body></html>], 'just pod';
}

{# title
	my $pod-str = qq:to[END];
		=TITLE
		This Title
		END
	is get-test-result($pod-str), q[<h1>This Title</h1>], 'just title';
}

{# heading
	my $pod-str = qq:to[END];
		=head1
		Heading1

		=head2
		Heading2

		=head1
		Heading11
		END
	is get-test-result($pod-str),
		q[<h1>Heading1</h1>] ~
		q[<h2>Heading2</h2>] ~
		q[<h1>Heading11</h1>], 'just headings';
}

