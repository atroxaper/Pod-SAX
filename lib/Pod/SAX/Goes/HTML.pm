module Pod::SAX::Goes::HTML {
	use Pod::SAX::Reformer;
	use Pod::SAX::Anchors;
	use Pod::SAX::Common;
	use Pod::SAX::Iter;

	my $N = "\n";

	sub render-toc(:%storage) {
		return True, '' unless %storage<toc>;
		my @result;
		my @with-headers = @(%storage<toc>);

		my $c-level = 0;
		push @result, '<nav class="indexgroup">';
		for @with-headers -> @head {
			my $n-level = @head[0];
			# render <ol> and </ol> #
			loop (my $i = $c-level + 1; $i <= $n-level; ++$i) {
				@result.push(qq[<ol class="indexList indexList{$i}">]);
			}
			loop ($i = $c-level; $i > $n-level; --$i) {
				@result.push(q[</ol>]);
			}
			$c-level = $n-level;
			# render <li><a></a></li> #
			@result.push(qq[<li class="indexItem indexItem{$c-level}"><a href="#{@head[1]}">{@head[2]}</a></li>]);
		}
		# last </ol>s #
		loop (my $i = $c-level; $i > 0; --$i) {
			@result.push(q[</ol>]);
		}
		push @result, "</nav>";
		return True, @result.join;
	}

	my @comment =
		:() => {
			in => sub (:$content) { say qq[find comment: $content]; }
		};
	my @named =
		# =begin pod #
		:(:$name where {$name ~~ 'pod'}) => {
			start => sub (:@draft) {
				@draft.push(
					qq[<!doctype html>{$N}<html>{$N}<head>{$N}],
					SimpleAnchor.new(:template(qq[<title><%=TITLE%></title>{$N}])),
					qq[<link href="index.css" type="text/css" rel="stylesheet">{$N}],
					qq[</head>{$N}<body class="pod" id="___top">{$N}]
				);
			},
			stop => sub (:@draft) {
				@draft.push(qq[</body>{$N}</html>{$N}]);
			}
		},
		:(:$name where {$name ~~ any('VERSION', 'AUTHOR')}) => {
			start => sub (:@draft, :$name) { push @draft, qq[<section>{$N}<h1>{$name}</h1>{$N}]; },
			stop =>  sub (:@draft) { push @draft, qq[</section>{$N}]; }
		},
		:(:$name where {$name eq 'output'}) => {
			start => sub (:@draft) { push @draft, q[<samp>]},
			stop => sub (:@draft) { push @draft, q[</samp>]}
		};
	my @para =
		# that para is content of =TITLE #
		:(:@history where {@history.&under-name('TITLE')}) => {
			start => sub (:@draft) { push @draft, q[<h1>]; },
			in => sub (:$content, :@draft, :%storage) {
				push @draft, $content;
				%storage{'TITLE'} = $content;
			},
			stop => sub (:@draft) {
				push @draft, qq[</h1>{$N}];
				# TOC should be after the title of page #
				my $toc = CallbackAnchor.new(:callback(&render-toc), :priority(1));
				push @draft, $toc;
			}
		},
		# that para is content of =head #
		:(:@history where {@history.&under-type(Pod::Heading)}) => {
			start => sub { True; },
			in => sub (:$content, :@draft, :%storage) {
				push @draft, qq[<a class="u" href="#___top" title="go to top document">{$content}</a>];
			},
			stop => sub { True; }
		},
		# that para is content of =begin output #
		:(:@history where {@history.&under-name('output')}) => {
			start => sub { True; },
			in => sub (:$content, :@draft) { push @draft, $content },
			stop => sub (:@draft) { push @draft, q[</br>]; }
		},
		# General Paragraph #
		:() => {
			start => sub (:@draft) { push @draft, "<p>"; },
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) { push @draft, "</p>{$N}"; }
		};
	my @table =
		:() => {
			start => sub (:$caption, :@headers, :@draft) {
				push @draft, qq[<table>{$N}];
				# render headers #
				if (@headers && +@headers > 0) {
					push @draft, qq[<thead>{$N}<tr>{$N}];
					for @headers -> $header {
						push @draft, qq[<th>{$header}</th>{$N}];
					}
					push @draft, qq[</tr>{$N}</thead>{$N}];
				}

				push @draft, qq[<tbody>{$N}];
			},
			in => sub (:$content, :@draft) {
				push @draft, qq[<tr>{$N}];
				for @($content) -> $td {
					push @draft, qq[<td>{$td}</td>{$N}];
				}
				push @draft, qq[</tr>{$N}];
			},
			stop => sub (:@draft) {	push @draft, qq[</tbody>{$N}</table>{$N}]; }
		};
	my @formatting =
		:(:$type where {$type ~~ 'L'}) => {
			start => sub (:@draft, :@meta, :$instance) {
				my $good-meta;
				if @meta {
					$good-meta = @meta[0];
				} else { # if meta is't declared than we get bare content
			 		$good-meta = get-bare-content($instance);
			 	}
			 	# parse scheme
			 	# maybe it would better to write special Action for that
			 	my $m = MetaL.parse($good-meta);
			 	if ($m<scheme> && $m<scheme><type> eq 'doc' && $m<intern>) {
			 		$good-meta = "$m<intern>";
			 	} elsif ($m<scheme> && $m<scheme><type> eq 'defn') {
			 		sub test(:%storage, :%custom) {
						my $search = %custom<search>;
						my $found = %storage{$search} || '_defn_' ~ $search;
						return True, '#' ~ $found;
					}
					my %custom = search => "$m<extern>";
					$good-meta = CallbackAnchor.new(:callback(&test), :custom(%custom));
			 	} elsif ($m<scheme> && $m<scheme><type> ~~ any('http', 'https')
			 			&& $m<extern> && $m<extern><from-root>.from == $m<extern><from-root>.to) {
			 		$good-meta = "$m<extern><path>";
			 		$good-meta ~= "$m<intern>" if $m<intern>;
			 	}
			 	$good-meta = escape_id($good-meta) if $good-meta ~~ Str;

				push @draft, q[<a href="], $good-meta, q[">];
			},
			in => sub (:@draft, :$content) {
				push @draft, $content;
			},
			stop => sub (:@draft) {	push @draft, qq[</a>]; }
		},
		:(:$type where {$type ~~ 'C'}) => {
			start => sub (:@draft) { push @draft, q[<code>]; },
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) { push @draft, q[</code>]; }
		},
		:(:$type where {$type ~~ 'D'}) => {
			start => sub (:@draft) { push @draft, qq[{$N}<dfn id="]; },
			in => sub (:@draft, :$content, :%storage, :@meta) {
				my $id = '_defn_' ~ escape_id($content);
				push @draft, qq[{$id}">];
				push @draft, $content;
				%storage{$content} = $id;
				%storage{$_} = $id for @meta;
			},
			stop => sub (:@draft) { push @draft, qq[</dfn>]; }
		},
		:(:$type where {$type ~~ 'I'}) => {
			start => sub (:@draft) { push @draft, qq[{$N}<em>]; },
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) { push @draft, qq[</em>]; }
		},
		:(:$type where {$type ~~ 'B'}) => {
			start => sub (:@draft) { push @draft, q[<strong>]},
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) { push @draft, q[</strong>]}
		},
		:(:$type where {$type ~~ 'R'}) => {
			start => sub (:@draft) { push @draft, q[<var>]},
			in => sub (:@draft, :$content) { push @draft, escape_html($content); },
			stop => sub (:@draft) { push @draft, q[</var>]}
		};
	my @heading =
		:() => {
			start => sub (:@draft, :$level, :$instance, :%storage) {
				my $bare = get-bare-content($instance);
				my $bare-id = escape_id($bare);
				push @draft, qq[<h{$level} id="{$bare-id}">];
				my @toc = @(%storage<toc>) || ();
				@toc[+@toc] = $level, $bare-id, $bare;
				%storage<toc> = @toc;
			},
			stop => sub (:@draft, :$level) { push @draft, qq[</h{$level}>]; }
		};
	my @code =
		:() => {
			start => sub (:@draft) { push @draft, qq[<pre>]; },
			in => sub (:@draft, :$content) { push @draft, escape_html($content); },
			stop => sub (:@draft) { push @draft, qq[</pre>]; }
		};

	sub make-reformer() is export {
		my Reformer $reformer .= new;
		$reformer.callbacks{Pod::Block::Comment.^name} = @comment;
		$reformer.callbacks{Pod::Block::Named.^name} = @named;
		$reformer.callbacks{Pod::Block::Para.^name} = @para;
		$reformer.callbacks{Pod::Block::Table.^name} = @table;
		$reformer.callbacks{Pod::FormattingCode.^name} = @formatting;
		$reformer.callbacks{Pod::Heading.^name} = @heading;
		$reformer.callbacks{Pod::Block::Code.^name} = @code;

		return $reformer;
	}

	# I stole that sub from L<Pod::To::HTML module|https://github.com/perl6/Pod-To-HTML>
	sub escape_html(Str $str) returns Str {
        return $str unless $str ~~ /<[&<>"']>/;

        $str.trans( [ q{&},     q{<},    q{>},    q{"},      q{'}     ] =>
                    [ q{&amp;}, q{&lt;}, q{&gt;}, q{&quot;}, q{&#39;} ] );
    }

    # I stole that sub from L<Pod::To::HTML module|https://github.com/perl6/Pod-To-HTML>
    sub escape_id ($id) {
        $id.subst(/\s+/, '_', :g);
    }
}