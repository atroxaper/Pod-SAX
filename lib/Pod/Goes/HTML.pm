module Pod::Goes::HTML {
	use Pod::Callback;

	my $N = "\n";

	my @comment =
		sub { True; } => {
			in => sub (:$content) { say qq[find comment: $content]; True; }
		};
	my @named =
		# =begin pod
		sub ( :$name where {$name ~~ "pod"}) { True; } => {
			start => sub (:@draft) {
				@draft.push(
					qq[<!doctype html>{$N}<html>{$N}<head>{$N}],
					SimpleAnchor.new(:template(qq[<title><%=TITLE%></title>{$N}])),
					qq[</head>{$N}<body class="pod" id="___top">{$N}]
				);
				True;
			},
			stop => sub (:@draft) {
				@draft.push(qq[</body>{$N}/html>{$N}]);
				True;
			}
		};
	my @para =
		# Title #
		sub (:@history where {@history && @history[*-1] ~~ Pod::Block::Named && @history[*-1].name ~~ 'TITLE'}) { True; } => {
			in => sub (:$content, :@draft, :%storage) {
				push @draft, qq[<h1>{$content}</h1>{$N}];
				%storage{'TITLE'} = $content; True;
			}
		};

	sub make-caller() is export {
		my Caller $caller .= new;
		$caller.callbacks{Pod::Block::Comment.^name} = @comment;
		$caller.callbacks{Pod::Block::Named.^name} = @named;
		$caller.callbacks{Pod::Block::Para.^name} = @para;

		return $caller;
	}
}