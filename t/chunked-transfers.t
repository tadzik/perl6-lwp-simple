use v6;
use Test;
use LWP::Simple;

my $lwp = LWP::Simple.new;
ok($lwp, 'Object create');

#
# Test that not chunked pages are interpreted correctly
#

my $testcase-no-chunked =
q<HTTP/1.1 200 OK
Server: random/3.14
Content-type: text/plain

3c
This response shouldn't be interpreted as chunked,
since there is no "Transfer-Encoding: chunked" header
>;

my ($status, $headers, $content) = $lwp.parse_response($testcase-no-chunked);
is($status, q<HTTP/1.1 200 OK>, 'Status parsed correctly');

# Only way to dereference I have found
my %headers = $headers;
is(%headers<Server>, 'random/3.14', 'Server header parsed correctly');
is(%headers<Content-type>, 'text/plain', 'Content-type header parsed correctly');
ok(! %headers.exists('Transfer-Encoding'), 'Transfer-Encoding header not found');

my $content_str = $content.join('\n');
ok(
    $content_str && $content_str.match('3c'),
    'Content contains fake chunked transfer markers'
);

#
# Test that chunked pages are interpreted correctly
#

my $testcase-chunked =
q<HTTP/1.0 200 OK
Server: Apache/2.2.9
Transfer-Encoding: Chunked
Content-type: text/plain

0f
15 characters
10
another 16 here
0

>;

($status, $headers, $content) = $lwp.parse_response($testcase-chunked);
is($status, q<HTTP/1.0 200 OK>, 'Status parsed correctly');

# Only way to dereference I have found
%headers = $headers;
is(%headers<Server>, 'Apache/2.2.9', 'Server header parsed correctly');
is(%headers<Content-type>, 'text/plain', 'Content-type header parsed correctly');

# rakudo: $str ~~ m:i// NIY
ok(%headers<Transfer-Encoding> ~~ m/:i chunked/, 'Transfer-Encoding found');

$content_str = $content.join('\n');
ok(
    $content_str && ! $content_str.match('0f'),
    'Content should not contain chunked transfer markers'
);

done_testing;
