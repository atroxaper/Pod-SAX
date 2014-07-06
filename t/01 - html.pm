use v6;

use Test;

use Pod::Goes::HTML;
use Pod::Nearby;

plan 1;

sub get-test-result(Str $source --> Str) {
	my Nearer $nearer = make-nearer;
	my $pod = get-pod($source);
	$nearer.approach-to($pod);
	return $nearer.get-result.subst(/\n/, '', :g);
}

{# title
	my $pod-str = qq:to[END];
		=begin pod

		=TITLE
		This Title

		=end pod
		END
	my $expect = qq:to[END];
		<!doctype html><html><head>
		<title>This Title</title>
		</head><body class="pod" id="___top">
		<h1>This Title</h1>
		</body></html>
		END
	is get-test-result($pod-str), $expect.subst(/\n/, '', :g), 'just title';
}

