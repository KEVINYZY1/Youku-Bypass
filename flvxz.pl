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
    ($b =~ m/[&?]hd=(\d+)/)[0] <=> ($a =~ /[&?]hd=(\d+)/)[0]
} grep { /hd=/ } keys %videos, grep { !/hd=/ } keys %videos);

die "Invalid response, try launch the script again (Or report bugs to moi) -_-! " unless @urls;

my $highest = ($urls[0] =~ /[&?]hd=(\d+)/)[0];
my @best_set = sort {
    $videos{$a} cmp $videos{$b}
} grep { /hd=$highest/ } @urls;

# Empty set? Hmm
@best_set = @urls if ! @best_set;

# 1. mplayer
&mplayer (@best_set), exit (0) if $opts{mplayer};

# 2. aria2c
&aria2c (@best_set), exit (0) if $opts{aria2c};

# 3. no selection, last resort?
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
	for (split q{<a }, $resp->decoded_content)
    {
        if (/href="([^"]+)"[^>]*>(.*)<\/a>/)
        {
            my ($url, $name) = ($1, $2);
            next unless $url =~ /f\.youku\.com/ and $name =~ /\./;
            $data{$url} = $name;
        }
	}

    return %data;
}

sub help
{
	print<<EOF

Flvxz toolset, locate video urls
[FYI: name resolution is broken on remote site, fuck them]

Usage: $0 [options] [url]

    -help      you're reading this baby!

    -aria2c    generate shell script for aria2c
    -mplayer   play video directly

EOF
    ;
    exit (0);
};
