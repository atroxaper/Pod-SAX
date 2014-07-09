use v6;

use Test;

use Pod::SAX::Goes::HTML;
use Pod::SAX::Reformer;
use Pod::SAX::Common;

plan 8;

sub rm-n($str) {
	return $str.subst(/\n/, '', :g);
}

sub get-test-result(Str $source --> Str) {
	my Reformer $reformer = make-reformer;
	my $pod = get-pod($source);
	$reformer.reform($pod);
	return $reformer.get-result.&rm-n;
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

{# links
	my %links =
		'L<http://www.mp3dev.org/mp3/>' => q[<a href="http://www.mp3dev.org/mp3/"],
		'L<name|link>' => q[<a href="link">name</a>],
		'L<#name>' => q[<a href="#name">name</a>],
		'L<C<name>>' => q[<a href="#"><code>name<code></a>],
		'L<name>' => q[<a href="name">name</a>];
	my $pod-str = qq:to[END];
		=para
		content
		END
	for %links.kv -> $k, $v {
		is get-test-result($pod-str.subst(/content/, $k)), '<p>' ~ $v ~ '</p>', 'link: ' ~ $k;
	}
}

