module Pod::Goes::HTML {
	use Pod::Nearby;

	my $N = "\n";

	my @comment =
		sub { True; } => {
			in => sub (:$content) { say qq[find comment: $content]; True; }
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
				True;
			},
			stop => sub (:@draft) {
				@draft.push(qq[</body>{$N}</html>{$N}]);
				True;
			}
		},
		sub (:$name where {$name ~~ any('VERSION', 'AUTHOR')}) { True; } => {
			start => sub (:@draft, :$name) { push @draft, qq[<section>{$N}<h1>{$name}</h1>{$N}]; True; },
			stop =>  sub (:@draft) { push @draft, qq[</section>{$N}]; True; },
		};
	my @para =
		# Title #
		sub (:@history where {@history.&under-name('TITLE')}) { True; } => {
			start => sub (:@draft) { push @draft, q[<h1>]; True; },
			in => sub (:$content, :@draft, :%storage) {
				push @draft, qq[{$content}{$N}];
				%storage{'TITLE'} = $content;
				True;
			},
			stop => sub (:@draft) { push @draft, q[</h1>]; True; }
		},
		# General Paragraph #
		sub { True; } => {
			start => sub (:@draft) { push @draft, "<p>"; True; },
			in => sub (:@draft, :$content) { push @draft, $content; True; },
			stop => sub (:@draft) { push @draft, "</p>"; True; },
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
				True;
			},
			in => sub (:$content, :@draft) {
				push @draft, qq[<tr>{$N}];
				for @($content) -> $td {
					push @draft, qq[<td>{$td}</td>{$N}];
				}
				push @draft, qq[</tr>{$N}];
				True;
			},
			stop => sub (:@draft) {	push @draft, qq[</tbody>{$N}</table>{$N}]; True; }
		};
	my @formatting =
		sub (:$type where {$type ~~ 'L'}) { True; } => {
			start => sub (:@draft, :@meta) { push @draft, qq[<a href="{@meta[0]}">]; True; },
			stop => sub (:@draft) {	push @draft, qq[</a>]; True; }
		},
		sub (:$type where {$type ~~ 'C'}) { True; } => {
			start => sub (:@draft) { push @draft, qq[<code>]; True; },
			in => sub (:@draft, :$content) { push @draft, $content; True; },
			stop => sub (:@draft) { push @draft, q[</code>]; True; }
		};

	sub make-nearer() is export {
		my Nearer $nearer .= new;
		$nearer.callbacks{Pod::Block::Comment.^name} = @comment;
		$nearer.callbacks{Pod::Block::Named.^name} = @named;
		$nearer.callbacks{Pod::Block::Para.^name} = @para;
		$nearer.callbacks{Pod::Block::Table.^name} = @table;
		$nearer.callbacks{Pod::FormattingCode.^name} = @formatting;

		return $nearer;
	}
}