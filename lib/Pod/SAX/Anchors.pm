module Pod::SAX::Anchors {
	role Anchor is export {
		method prepared(--> Bool) { ... }
		method priority(--> Int) { ... }
		method prepare(--> Bool) { ... }
	}

	class SimpleAnchor does Anchor is export {
		# for role satisfaction  #
		has Bool $.prepared is rw = False;
		has Int $.priority = 0;

		has $.template is rw;
		has %.storage is rw;

		has $!result = '';

		multi method gist() {
			return $!result;
		}

		multi method Str() {
			return $!result;
		}

		method prepare() {
			my $this = self;
			self.template ~~ m:g/ '<%' ['=']? $<key>=[ [ <!before '%>' > . ]* ] '%>' { unless $this.storage{$<key>.Str} {
				$this.prepared = False;
				return $this.prepared;
			}} /;
			$!result = $.template;
			$!result ~~ s:g/ '<%' ['=']? $<key>=[ [ <!before '%>' > . ]* ] '%>' /%.storage{$<key>.Str}/;
			$.prepared = True;
			return $.prepared;
		}
	}

	#| Initialize Anchor object some dates by is rw fields ob object.
	#| Now we can insert only current %storage and @draft.
	sub init-anchor($anchor, %args) is export {
		for $anchor.^attributes.grep({.rw}) {
			my $name = $_.name.substr(2);
			if ($name ~~ any(%args.keys)) {
				$anchor."$name"() = %args{$name};
			}
		}
	}
}