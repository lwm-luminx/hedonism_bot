# The apt buildpack puts exiftool on PATH but not its Perl modules.
export PERL5LIB="$HOME/.apt/usr/share/perl5:$PERL5LIB"
