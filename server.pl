#!/usr/bin/perl

use lib qw(./modules/lib/5.16.2);
use MIME::Types;
 {
 package MyWebServer;
 
 use HTTP::Server::Simple::CGI;
 use base qw(HTTP::Server::Simple::CGI);

 my %dispatch = (
     '/hello' => \&resp_hello,
     # ...
 );
 
 sub handle_request {
     my $self = shift;
     my $cgi  = shift;
   
     my $path = $cgi->path_info();
     my $handler = $dispatch{$path};

     # Get rid of leading/trailing slashes on path
     my ($filename) = $path;
     $filename =~ s/^\///;
     $filename =~ s/\/$//;

     # If not filename, index this directory
     $filename = "." if (length($filename) == 0);

     # If path points to a directory
     $filename = $filename."/index.html"
       if (-d $filename && -e $filename."/index.html");
     
     # If this is a reference to a sub, the result is
     # whatever the sub does
     if (ref($handler) eq "CODE") {
         print "HTTP/1.0 200 OK\r\n";
         $handler->($cgi);
     } elsif (-e $filename) {
         # Serve a file, if it exists.
         my ($mt) = MIME::Types->new();
         my ($type) = $mt->mimeTypeOf($filename);

         # Read the file
         if (!open FILE, "<$filename") {
             print "HTTP/1.0 500 Error\r\n";
             print "Content-type: text/html\r\n";
             print "\r\n<h1>500 Server Error</h1><p>$filename: $!</p>\r\n";
         } else {
             binmode FILE;
             my ($buf, $buf, $n, $data);
             my ($len) = 0;
             while (($n = read FILE, $buf, 1000000) != 0) {
                 $len += $n;
                 $data .= $buf;
             }
             close(FILE);

             print "HTTP/1.0 200 Found\r\n";
             print "Content-type: $type\r\n";
             print "Content-length: $len\r\n";
             print "\r\n";
             print $data;
         }
     } else {
         print "HTTP/1.0 404 Not found\r\n";
         print $cgi->header,
               $cgi->start_html('Not found'),
               $cgi->h1('Not found'),
               $cgi->end_html;
     }
 }
 
 sub resp_hello {
     my $cgi  = shift;   # CGI.pm object
     return if !ref $cgi;
     
     my $who = $cgi->param('name');
     my $times = $cgi->param('times');
     my $n;
     
     print $cgi->header,
           $cgi->start_html("Hello"),
           $cgi->h1("Greeting $who, $times times"),
           $cgi->ol;
     for ($n = 0; $n < $times; $n++) {
           print $cgi->li("Hello $who!"),
     }
     print $cgi->end_html;
 }
 
 } 
 
 # start the server on port 8080
 my $pid = MyWebServer->new(8080)->background();
 print "Use 'kill $pid' to stop server.\n";

