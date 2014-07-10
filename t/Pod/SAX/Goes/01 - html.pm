use v6;

use Test;

use Pod::SAX::Goes::HTML;
use Pod::SAX::Reformer;
use Pod::SAX::Common;

plan 23;

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
		'L<http://www.mp3dev.org/mp3/>' => q[<a href="http://www.mp3dev.org/mp3/">http://www.mp3dev.org/mp3/</a>],
		'L<http://perlcabal.org/syn/S04.html#The_for_statement>' => q[<a href="http://perlcabal.org/syn/S04.html#The_for_statement">http://perlcabal.org/syn/S04.html#The_for_statement</a>],
		'L<http:tutorial/faq.html>' => q[<a href="tutorial/faq.html">http:tutorial/faq.html</a>],
		'L<file:/usr/local/lib/.configrc>' => q[<a href="file:/usr/local/lib/.configrc">file:/usr/local/lib/.configrc</a>],
		'L<file:.configrc>' => q[<a href="file:.configrc">file:.configrc</a>],
		'L<mailto:devnull@rt.cpan.org>' => q[<a href="mailto:devnull@rt.cpan.org">mailto:devnull@rt.cpan.org</a>],
		'L<man:find(1)>' => q[<a href="man:find(1)">man:find(1)</a>],
		'L<doc:perldata>' => q[<a href="doc:perldata">doc:perldata</a>],
		'L<doc:#Special Features>' => q[<a href="#Special Features">doc:#Special Features</a>],
		'L<#Special Features>' => q[<a href="#Special Features">#Special Features</a>],
		'L<defn:lexiphania>' => q[<a href="#_defn_lexiphania">defn:lexiphania</a>],
		'L<issn:1087-903X>' => q[<a href="issn:1087-903X">issn:1087-903X</a>],
		'L<isbn:2-266-11156-6>' => q[<a href="isbn:2-266-11156-6">isbn:2-266-11156-6</a>],
		'L<name|link>' => q[<a href="link">name</a>],
		'L<C<name>>' => q[<a href="name"><code>name</code></a>],
		'L<C<n>amC<e>>' => q[<a href="name"><code>n</code>am<code>e</code></a>],
		'L<name>' => q[<a href="name">name</a>];
	my $pod-str = qq:to[END];
		=para
		content
		END
	for %links.kv -> $k, $v {
		is get-test-result($pod-str.subst(/content/, $k)), '<p>' ~ $v ~ '</p>', 'link: ' ~ $k;
	}
}

{#| D<> and L<defn:>
	my $pod-str = qq:to[END];
		=begin para

		D<term-one|termone;term_one;term1;term-1;term_1>
		L<defn:term-one>
		L<term-one(click)|defn:term_one>
		L<defn:term-1>
		L<defn:1-term>

		=end para
		END
	is get-test-result($pod-str),
		q[<p><dfn id="_defn_term-one">term-one</dfn>] ~
		q[ <a href="#_defn_term-one">defn:term-one</a>] ~
		q[ <a href="#_defn_term-one">term-one(click)</a>] ~
		q[ <a href="#_defn_term-one">defn:term-1</a>] ~
		q[ <a href="#_defn_1-term">defn:1-term</a></p>], 'link to defn';
}

{#| test Pod::Block::Code (=begin code)
	my $pod-str = q:to[END];
		=begin code :allow<B>
			B<=begin pod>

			=head1 A heading

			This is Pod too. Specifically, this is a simple C<para> block

				$this = pod('also');  # Specifically, a code block

			B<=end pod>
		=end code
		END
	is get-test-result($pod-str),
		q[<pre>	<strong>=begin pod</strong>] ~
		q[	=head1 A heading] ~
		q[	This is Pod too. Specifically, this is a simple C&lt;para&gt; block] ~
		q[		$this = pod(&#39;also&#39;);  # Specifically, a code block] ~
		q[	<strong>=end pod</strong></pre>], '=begin code reforms well';
}

{#| test B<> and I<> R<>
	my $pod-str = qq:to[END];
		=begin para
		Text B<bold> and I<italic> and B<I<both>> and I<B<in back order>>. And now R<metasyntactic>.
		=end para
		END
    is get-test-result($pod-str),
		q[<p>Text <strong>bold</strong> and <em>italic</em> and ] ~
		q[<strong><em>both</em></strong> and <em><strong>in back order</strong></em>. ] ~
		q[And now <var>metasyntactic</var>.</p>], 'B<> and I<> and R<> work well';
}

