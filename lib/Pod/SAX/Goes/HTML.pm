module Pod::SAX::Goes::HTML {
	use Pod::SAX::Reformer;
	use Pod::SAX::Anchors;
	use Pod::SAX::Common;
	use Pod::SAX::Iter;

	my $N = "\n";

	my @comment =
		sub { True; } => {
			in => sub (:$content) { say qq[find comment: $content]; }
		};
	my @named =
		# =begin pod
		sub (:$name where {$name ~~ 'pod'}) { True; } => {
			start => sub (:@draft) {
				@draft.push(
					qq[<!doctype html>{$N}<html>{$N}<head>{$N}],
					SimpleAnchor.new(:template(qq[<title><%=TITLE%></title>{$N}])),
					qq[</head>{$N}<body class="pod" id="___top">{$N}]
				);
			},
			stop => sub (:@draft) {
				@draft.push(qq[</body>{$N}</html>{$N}]);
			}
		},
		sub (:$name where {$name ~~ any('VERSION', 'AUTHOR')}) { True; } => {
			start => sub (:@draft, :$name) { push @draft, qq[<section>{$N}<h1>{$name}</h1>{$N}]; },
			stop =>  sub (:@draft) { push @draft, qq[</section>{$N}]; }
		};
	my @para =
		# Title #
		sub (:@history where {@history.&under-name('TITLE')}) { True; } => {
			start => sub (:@draft) { push @draft, q[<h1>]; },
			in => sub (:$content, :@draft, :%storage) {
				push @draft, qq[{$content}];
				%storage{'TITLE'} = $content;
			},
			stop => sub (:@draft) { push @draft, q[</h1>]; }
		},
		sub (:@history where {@history.&under-type(Pod::Heading)}) { True; } => {
			start => sub { True; },
			in => sub (:$content, :@draft, :%storage) {
				push @draft, $content;
				# TODO add code for table of contents
			},
			stop => sub { True; }
		},
		# General Paragraph #
		sub { True; } => {
			start => sub (:@draft) { push @draft, "<p>"; },
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) { push @draft, "</p>{$N}"; }
		};
	my @table =
		sub { True; } => {
			start => sub (:$caption, :@headers, :@draft) {
				return True if @headers && @headers.size > 0;
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
		sub (:$type where {$type ~~ 'L'}) { True; } => {
			start => sub (:@draft, :@meta, :$content, :$instance) {
				my $good-meta;
				if @meta {
					$good-meta = @meta[0];
				} else { # if meta is't declared than we get bare content
			 		my PodIterator $iter .= new;
			 		$iter.init($instance);
			 		my @pair;
			 		my @for-good-meta;
			 		while (@pair = $iter.get-next).elems > 1 {
			 			@for-good-meta.push(@pair[0]) if @pair[1] == 0;
			 		}
			 		$good-meta = @for-good-meta.join;
			 	}
			 	# parse scheme
			 	# maybe it would better to write special Action for that
			 	my $m = MetaL.parse($good-meta);
			 	if ($m<scheme> && $m<scheme><type> eq 'doc' && $m<intern>) {
			 		$good-meta = $m<intern>;
			 	} elsif ($m<scheme> && $m<scheme><type> eq 'defn') {
			 		sub test(:%storage, :%custom) {
						my $search = %custom<search>;
						my $found = %storage{$search} || '_defn_' ~ $search;
						return True, '#' ~ $found;
					}
					$good-meta = CallbackAnchor.new(:callback(&test), :custom({search => $m<extern>}));
			 	} elsif ($m<scheme> && $m<scheme><type> ~~ any('http', 'https')
			 			&& $m<extern> && $m<extern><from-root>.from == $m<extern><from-root>.to) {
			 		$good-meta = $m<extern><path>;
			 		$good-meta ~= $m<intern> if $m<intern>;
			 	}

				push @draft, q[<a href="], $good-meta, q[">];
			},
			in => sub (:@draft, :$content) {
				push @draft, $content;
			},
			stop => sub (:@draft) {	push @draft, qq[</a>]; }
		},
		sub (:$type where {$type ~~ 'C'}) { True; } => {
			start => sub (:@draft) { push @draft, q[<code>]; },
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) { push @draft, q[</code>]; }
		},
		sub (:$type where {$type ~~ 'D'}) { True; } => {
			start => sub (:@draft) { push @draft, qq[{$N}<dfn id="]; },
			in => sub (:@draft, :$content, :%storage, :@meta) {
				my $id = '_defn_' ~ $content;
				push @draft, qq[{$id}">];
				push @draft, $content;
				%storage{$content} = $id;
				%storage{$_} = $id for @meta;
			},
			stop => sub (:@draft) { push @draft, qq[</dfn>]; }
		},
		sub (:$type where {$type ~~ 'I'}) { True; } => {
			start => sub (:@draft) { push @draft, qq[{$N}<em>]; },
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) { push @draft, qq[</em>]; }
		},
		sub (:$type where {$type ~~ 'B'}) { True; } => {
			start => sub (:@draft) { push @draft, q[<strong>]},
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) { push @draft, q[</strong>]}
		},
		sub (:$type where {$type ~~ 'R'}) { True; } => {
			start => sub (:@draft) { push @draft, q[<var>]},
			in => sub (:@draft, :$content) { push @draft, escape_html($content); },
			stop => sub (:@draft) { push @draft, q[</var>]}
		};
	my @heading =
		sub { True; } => {
			start => sub (:@draft, :$level) { push @draft, qq[<h{$level}>]; },
			stop => sub (:@draft, :$level) { push @draft, qq[</h{$level}>]; }
		};
	my @code =
		sub { True; } => {
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
}