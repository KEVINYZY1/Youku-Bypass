#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use MIME::Base64;
use Getopt::Long;
use LWP::UserAgent;

my %opts = ();
my $ua = LWP::UserAgent->new;
my @choosen = ();

sub getUrlMapping
{
	my $url = shift or die;
	$url = 'http://' . $url unless $url =~ /http:/;
	
    my %d = ();
	my $resp = $ua->get ('http://www.flvxz.com/getFlv.php?url=' . encode_base64 ($url));
	for (split q{</a>}, $resp->decoded_content)
	{
		if ($_ =~ /red">\[(.*)\]<\/span.*href="([^"]+)"/)
		{
			$d{$1} = $2;
		}
	}

	return \%d;
};

sub help
{
	print<<EOF

	Youku Simple:  Locate video URL

    usage: ./youku_simple.pl [options] [url]

	-help      you're reading this baby!

	-pattern   filter on segment name
	-aria2c    generate aria2c shell script

	-select    select preferred video with zenity
    -mplayer   play video directly

EOF
	;
	exit (0);
};

GetOptions (\%opts, 'mplayer|m', 'select|s', 'pattern|p=s', 'help|h', 'aria2c|a') or help;
$#ARGV eq 0 or help;

my $hashref = getUrlMapping ($ARGV[0]);
#@list = ("&hd=1", "fff", "&hd=2"); [((reverse sort grep /&hd=/, @list), (sort grep /^(?!&hd=)/, @list))]

###
if ($opts{mplayer})
{
	my @playlist = map { $hashref->{$_} } grep { /高清/ } sort keys $hashref;
	if (!@playlist)
	{
		@playlist = map { $hashref->{$_} } grep { /FLV/ } sort keys $hashref;
	}
	system ("mplayer", "-cache", "2000", @playlist);
	exit (0);
}

###
if ($opts{select})
{
	my @args = ('zenity', '--list', '--checklist', '--column', 'Pick', '--column', 'File');
	for (sort keys %$hashref)
	{
		if ($opts{pattern} and $_ =~ /$opts{pattern}/)
		{
			push @args, 'TRUE';
		}
		else
		{
			push @args, 'FALSE';
		}
		push @args, $_;
	}

	push @args, '--separator=:';
	my $output = system (@args);
	@choosen = split /:/, $output;

	print join ("|", @choosen);
}
else
{
	@choosen = keys %$hashref;
}

for (@choosen)
{
	if (! $opts{select} && $opts{pattern})
	{
		next if $_ !~ /$opts{pattern}/;
	}
	if ($opts{aria2c})
	{
		print 'aria2c "', $hashref->{$_}, '" -o "', $_, '"', "\n";
	}
	else
	{
		print "[ $_ ] ", $hashref->{$_}, "\n";
	}
}
