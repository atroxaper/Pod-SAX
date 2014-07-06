module Pod::Goes::HTML {
	use Pod::Nearby;

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
			stop => sub (:@draft) { push @draft, "</p>"; }
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
			start => sub (:@draft, :@meta) { push @draft, qq[<a href="{@meta[0]}">]; },
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) {	push @draft, qq[</a>]; }
		},
		sub (:$type where {$type ~~ 'C'}) { True; } => {
			start => sub (:@draft) { push @draft, qq[<code>]; },
			in => sub (:@draft, :$content) { push @draft, $content; },
			stop => sub (:@draft) { push @draft, q[</code>]; }
		},
		sub (:$type where {$type ~~ 'D'}) { True; } => {
			start => sub (:@draft) { push @draft, qq[{$N}<dfn>]; },
			in => sub (:@draft, :$content, :$instance) {
				push @draft, qq[$content];
				# TODO what should we do with synonyms in @meta ?
			},
			stop => sub (:@draft) { push @draft, qq[</dfn>]; };
		};
	my @heading =
		sub { True; } => {
			start => sub (:@draft, :$level) { push @draft, qq[<h{$level}>]; },
			stop => sub (:@draft, :$level) { push @draft, qq[</h{$level}>]; }
		};

	sub make-nearer() is export {
		my Nearer $nearer .= new;
		$nearer.callbacks{Pod::Block::Comment.^name} = @comment;
		$nearer.callbacks{Pod::Block::Named.^name} = @named;
		$nearer.callbacks{Pod::Block::Para.^name} = @para;
		$nearer.callbacks{Pod::Block::Table.^name} = @table;
		$nearer.callbacks{Pod::FormattingCode.^name} = @formatting;
		$nearer.callbacks{Pod::Heading.^name} = @heading;

		return $nearer;
	}
}