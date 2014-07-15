use v6;

use Test;

use Pod::SAX::Goes::HTML;
use Pod::SAX::Reformer;
use Pod::SAX::Common;

plan 33;

# some consts #
my $heading-to-top = q[<a class="u" href="#___top" title="go to top document">];

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
		q[<link href="index.css" type="text/css" rel="stylesheet">] ~
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
		qq[<h1 id="Heading1">{$heading-to-top}Heading1</a></h1>] ~
		qq[<h2 id="Heading2">{$heading-to-top}Heading2</a></h2>] ~
		qq[<h1 id="Heading11">{$heading-to-top}Heading11</a></h1>], 'just headings';
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
		'L<doc:#Special Features>' => q[<a href="#Special_Features">doc:#Special Features</a>],
		'L<#Special Features>' => q[<a href="#Special_Features">#Special Features</a>],
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
#?rakudo.parrot skip 'have SIGSEGV [#122274]'
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

{# heading
	my $pod-str = qq:to[END];
		=begin pod

		=TITLE
		This Title

		=head1
		Heading 1

		=head2
		Heading 2

		=head1
		Heading 11

		=end pod
		END
	my $result = get-test-result($pod-str);
	$result ~~ m/'<h1>This Title</h1>'/;
	my $expect = qq:to[END];
		<nav class="indexgroup">
		<ol class="indexList indexList1">
		<li class="indexItem indexItem1"><a href="#Heading_1">Heading 1</a></li>
		<ol class="indexList indexList2">
		<li class="indexItem indexItem2"><a href="#Heading_2">Heading 2</a></li>
		</ol>
		<li class="indexItem indexItem1"><a href="#Heading_11">Heading 11</a></li>
		</ol>
		</nav>
		<h1 id="Heading_1">{$heading-to-top}Heading 1</a></h1>
		<h2 id="Heading_2">{$heading-to-top}Heading 2</a></h2>
		<h1 id="Heading_11">{$heading-to-top}Heading 11</a></h1>
		</body></html>
		END

	is $/.postmatch, $expect.&rm-n, 'table of contents';
}

{#| =begin output test. todo Grammar parses paragraphs wrong
	my $pod-str = qq:to[END];
		=begin output
		Name: Magic::Necrotelecomnicon:

		Desc: Base class for comms necromancy hierarchy

		Attrs:

			.elemental : Source of all power

		=end output
		END
	my $expect = qq:to[END];
		<samp>
		Name: Magic::Necrotelecomnicon:</br>
		Desc: Base class for comms necromancy hierarchy</br>
		Attrs:</br>
		.elemental : Source of all power</br>
		</samp>
		END
	is get-test-result($pod-str), $expect.&rm-n, '=output';
}

{# Lists
	my $pod-str = q:to[END];
		=begin para
		=item  Happy
		=item  Dopey
		=end para
		END
	is get-test-result($pod-str), q:to[END].&rm-n, 'unordered list';
		<p><ul>
		<li type="disc">Happy</br></li>
		<li type="disc">Dopey</br></li>
		</ul></p>
		END

	$pod-str = q:to[END];
		=begin para
		=item1  Animal
		=item2     Vertebrate
		=item2     Invertebrate

		=item1  Phase
		=item2     Solid
		=end para
		END
	is get-test-result($pod-str), q:to[END].&rm-n, 'unordered list with sublist';
		<p><ul>
		<li type="disc">Animal</br></li>
		<ul>
		   <li type="circle">Vertebrate</br></li>
		   <li type="circle">Invertebrate</br></li>
		</ul>
		<li type="disc">Phase</br></li>
		<ul>
		   <li type="circle">Solid</br></li>
		</ul>
		</ul></p>
		END

	$pod-str = q:to[END];
		=begin para
		=for item1 :numbered
		Visito

		=for item2 :numbered
		Veni

		=for item2 :numbered
		Vidi
		=end para
		END
	is get-test-result($pod-str), q:to[END].&rm-n, 'ordered list';
		<p><ol>
		<li type="1" value="1">Visito</br></li>
		<ol>
		<li type="I" value="1">Veni</br></li>
		<li type="I" value="2">Vidi</br></li>
		</ol>
		</ol></p>
		END

	$pod-str = q:to[END];
		=begin para
		=item1  # Visito
		=item2     # Veni
		=item2     # Vidi
		=end para
		END
	is get-test-result($pod-str), q:to[END].&rm-n, 'ordered list with #';
		<p><ol>
		<li type="1" value="1">Visito</br></li>
		<ol>
		<li type="1" value="1">Veni</br></li>
		<li type="1" value="2">Vidi</br></li>
		</ol>
		</ol></p>
		END

	$pod-str = q:to[END];
		=begin para
		=item V<#> introduces a comment
		=for item :!numbered
		# introduces a comment
		=end para
		END
	is get-test-result($pod-str), q:to[END].&rm-n, 'unordered list with #';
		<p><ul>
		<li type="disc"># introduces a comment</br></li>
		<li type="disc"># introduces a comment</br></li>
		</ul></p>
		END

	$pod-str = q:to[END];
		=begin para
		=item1 # Death
		=item1 # Beer

		The tools are:

		=item1 # Revolution
		=item1 # Deep-fried peanut butter sandwich
		=end para
		END
	is get-test-result($pod-str), q:to[END].&rm-n, 'tow ordered lists';
		<p><ol>
		<li type="1" value="1">Death</br></li>
		<li type="1" value="2">Beer</br></li>
		</ol>
		The tools are:
		<ol>
		<li type="1" value="1">Revolution</br></li>
		<li type="1" value="2">Deep-fried peanut butter sandwich</br></li>
		</ol></p>
		END

	$pod-str = q:to[END];
		=begin para
		=for item1
		# Retreat to remote Himalayan monastery

		=for item1
		# Learn the hidden mysteries of space and time

		I<????>

		=for item1 :continued
		# Prophet!
		=end para
		END
	is get-test-result($pod-str), q:to[END].&rm-n, 'two ordered lists in one list';
		<p><ol>
		<li type="1" value="1">Retreat to remote Himalayan monastery</br></li>
		<li type="1" value="2">Learn the hidden mysteries of space and time</br></li>
		</ol>
		<em>????</em>
		<ol>
		<li type="1" value="3">Prophet!</br></li>
		</ol></p>
		END

	$pod-str = q:to[END];
		=begin para
		=begin item :numbered
		Item

		Same item
		=end item

		=begin item :numbered
		Another item

		Continue another item
		=end item
		=end para
		END
	is get-test-result($pod-str), q:to[END].&rm-n, 'multi-paragraph list';
		<p><ol>
		<li type="1" value="1">Item</br>Same item</br></li>
		<li type="1" value="2">Another item</br>Continue another item</br></li>
		</ol></p>
		END
}
