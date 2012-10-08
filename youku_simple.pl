#!/usr/bin/perl -w

use strict;
use MIME::Base64;
use Getopt::Long;
use LWP::UserAgent;

# Options
my %opts = ();
# UA
my $ua = LWP::UserAgent->new;
# Choosen items
my @choosen = ();

sub getUrlMapping
{
	my %d = ();
	my $url = shift or die;
	my $r = $ua->get ('http://www.flvxz.com/getFlv.php?url=' . encode_base64 ($url));
	for (split /;/, $r->decoded_content)
	{
		if ($_ =~ /down\("(.*)","(.*)"/)
		{
			$d{$2} = $1;
		}
	}

	return \%d;
};

sub help
{
	print<<EOF

	Youku_simple:  locate video URL

	-pattern   filter on segment name
	-help      show this dialog
	-aria2c    generate aria2c shell script

	-select    show a selection box using zenity

EOF
	;
	exit (0);
};

GetOptions (\%opts, 'mplayer|m', 'select|s', 'pattern|p=s', 'help|h', 'aria2c|a') or help;
$#ARGV eq 0 or help;

my $hashref = getUrlMapping ($ARGV[0]);

###
if ($opts{mplayer})
{
	my @playlist = map { $hashref->{$_} } grep { /_hd_/ } sort keys $hashref;
	system ("mplayer", @playlist);
	exit (0);
}

###
if ($opts{select})
{
	my @args = ( 'zenity', '--list', '--checklist', '--column', 'Pick', '--column', 'File');
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
	if ( ! $opts{select} && $opts{pattern})
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
