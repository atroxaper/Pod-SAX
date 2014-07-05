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
		sub (:$name where {$name ~~ 'VERSION'}) { True; } => {
			start => sub (:@draft) { push @draft, qq[<section>{$N}<h1>VERSION</h1>{$N}]; True; },
			stop =>  sub (:@draft) { push @draft, qq[</section>{$N}]; True; },
		};
	my @para =
		# Title #
		sub (:@history where {@history.&under-name('TITLE')}) { True; } => {
			in => sub (:$content, :@draft, :%storage) {
				push @draft, qq[<h1>{$content}</h1>{$N}];
				%storage{'TITLE'} = $content;
				True;
			}
		};
	my @table =
		sub { True; } => {
			start => sub (:$caption, :@headers, :@draft) {
				push @draft, qq[<table>{$N}<thead>{$N}<tr>{$N}];
				for @headers -> $header {
					push @draft, qq[<th>{$header}</th>{$N}];
				}
				push @draft, qq[</tr>{$N}</thead>{$N}<tbody>{$N}];
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
		}

	sub make-nearer() is export {
		my Nearer $nearer .= new;
		$nearer.callbacks{Pod::Block::Comment.^name} = @comment;
		$nearer.callbacks{Pod::Block::Named.^name} = @named;
		$nearer.callbacks{Pod::Block::Para.^name} = @para;
		$nearer.callbacks{Pod::Block::Table.^name} = @table;

		return $nearer;
	}
}