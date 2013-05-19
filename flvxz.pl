#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use lib '/secure/Common/src/cpan';
use Getopt::Long;
use Data::Dumper;
use MIME::Base64;
use LWP::UserAgent;

my $ua = LWP::UserAgent->new;
my %opts = ();

####

&help unless (GetOptions (\%opts, 'mplayer|m', 'select|s', 'pattern|p=s', 'help|h', 'aria2c|a') and $#ARGV ne -1);

my %videos = get_one ($ARGV[0]);
my @urls = (sort {
    ($b =~ s/.*hd=//r) cmp ($a =~ s/.*hd=//r)
} grep { /hd=/ } keys %videos, grep { !/hd=/ } keys %videos);

die "Invalid response" unless @urls;
#print "[ $videos{$_} ] $_\n" for (@urls);

my $highest = ($urls[0] =~ s/.*hd=//r);
my @best_set = grep { /hd=$highest/ } @urls;

# 1. mplayer
&mplayer (@best_set) if $opts{mplayer};

# 2. aria2c
&aria2c (@best_set) if $opts{aria2c};

# 3. no selection
print "[ $videos{$_} ] $_\n" for (@best_set);

####

sub aria2c
{
    print "aria2c '$_' -o '$videos{$_}'\n" for @_;
};

sub mplayer
{
    my (@urls) = @_;
    unshift @urls, "2000";
    unshift @urls, "-cache";

    system ("mplayer", @urls);
}

sub get_one
{
    my ($url) = @_;
    my %data = ();

    $url = 'http://' . $url unless $url =~ q{^http://};
	my $resp = $ua->get ('http://www.flvxz.com/getFlv.php?url=' . encode_base64 ($url));
	for (split q{</a>}, $resp->decoded_content)
	{
		if ($_ =~ /red">\[(.*)\]<\/span.*href="([^"]+)"/)
		{
			$data{$2} = $1;
		}
	}

    return %data;
}

sub help
{
	print<<EOF

Flvxz toolset, locate video urls

[FYI: name resolution is broken on remote site, fuck them]

usage: $0 [options] [url]

    -help      you're reading this baby!

    -aria2c    generate shell script for aria2c
    -mplayer   play video directly

EOF
    ;
    exit (0);
};
