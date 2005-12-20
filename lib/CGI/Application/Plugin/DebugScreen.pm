package CGI::Application::Plugin::DebugScreen;

use strict;
use warnings;
use HTML::Template;
use Devel::StackTrace;
use IO::File;

our $VERSION = '0.02';

our $TEMPLATE = qq{
<html><!-- HTML::Template -->
   <head>
       <title>Error in <!-- TMPL_VAR NAME="title" --></title>
       <style type="text/css">
           body {
               font-family: "Bitstream Vera Sans", "Trebuchet MS", Verdana,
                           Tahoma, Arial, helvetica, sans-serif;
               color: #000;
               background-color: #E68200;
               margin: 0px;
               padding: 0px;
           }
           :link, :link:hover, :visited, :visited:hover {
               color: #000;
           }
           div.box {
               position: relative;
               background-color: #fff;
               border: 1px solid #aaa;
               padding: 4px;
               margin: 10px;
               -moz-border-radius: 10px;
           }
           div.infos {
               background-color: #fff;
               border: 3px solid #FFCC99;
               padding: 8px;
               margin: 4px;
               margin-bottom: 10px;
               -moz-border-radius: 10px;
           }
           h1 {
               margin: 0;
               color: #999999;
           }
           h2 {
               margin-top: 0;
               margin-bottom: 10px;
               font-size: medium;
               font-weight: bold;
               text-decoration: underline;
           }
           div.url {
               font-size: x-small;
           }
           pre {
               font-size: .8em;
               line-height: 120%;
               font-family: 'Courier New', Courier, monospace;
               background-color: #FFCC99;
               color: #333;
               border: 1px dotted #000;
               padding: 5px;
               margin: 8px;
               width: 90%;
           }
           pre b {
               font-weight: bold;
               color: #000;
               background-color: #E68200;
           }
       </style>
   </head>
   <body>
       <div class="box">
           <h1><!-- TMPL_VAR NAME="title" --></h1>

           <div class="url"><!-- TMPL_VAR NAME="url" --></div>
           <div class="infos">
               <!-- TMPL_VAR NAME="desc" --><br />
           </div>
           <div class="infos">
               <h2>StackTrace</h2>
               <table>

                   <tr>
                       <th>Package</th>
                       <th>Line   </th>
                       <th>File   </th>
                   </tr>
                   <!-- TMPL_LOOP NAME="stacktrace" -->
                       <tr>
                           <td><!-- TMPL_VAR NAME="package" --></td>

                           <td><!-- TMPL_VAR NAME="line" --></td>
                           <td><!-- TMPL_VAR NAME="filename" --></td>
                       </tr>
                       <tr>
                           <td colspan="3"><pre><!-- TMPL_VAR NAME="code_preview" --></pre></td>
                       </tr>
                   <!-- /TMPL_LOOP -->
               </table>
           </div>
       </div>
   </body>
</html>
};

sub import {
    my $self   = shift;
    my $caller = scalar caller;

    no strict 'refs';
    $caller->add_callback( 'init', sub{
        my $self = shift;
        my $de;
        $SIG{__DIE__} = sub{
            push @{$self->{__stacktrace}},[Devel::StackTrace->new(ignore_package=>[qw/CGI::Application::Plugin::DebugScreen Carp CGI::Carp/])->frames];
            die @_; # rethrow
        };
        *{"$caller\::report"} = \&debug_report;
    });
    $caller->add_callback( 'error', sub{
        my $self = shift;
        $self->report(@_);
    });
}

sub debug_report{
    my $self = shift;
    my $desc = shift;
    my $url = $self->query->url;
    my $title = ref $self || $self;

    my $stacks = $self->{__stacktrace}[0];

    my @stacktraces;
    for my $stack ( @{$stacks} ) {
        my %s;
        $s{package}  = exists $stack->{pkg} ? $stack->{pkg}  : $stack->{package};
        $s{filename} = $stack->{file} ? $stack->{file} : $stack->{filename};

        $s{package}  = html_escape($s{package});
        $s{filename} = html_escape($s{filename});
        $s{line}     = html_escape($stack->{line});
        $s{code_preview} = print_context($s{filename},$s{line});
        push @stacktraces, \%s;
    }

    my $t = HTML::Template->new(
        scalarref => \$TEMPLATE,
        die_on_bad_params => 0,
    );
    $t->param(
        title  => html_escape($title),
        url    => html_escape($url),
        desc   => html_escape($desc),
        stacktrace => \@stacktraces,
    );

    $self->header_props( -type => 'text/html' );
    my $headers = $self->_send_headers();
    print $headers.$t->output;
}

sub print_context {
    my($file, $linenum) = @_;
    my $code;
    if (-f $file) {
        my $start = $linenum - 3;
        my $end   = $linenum + 3;
        $start = $start < 1 ? 1 : $start;
        if (my $fh = IO::File->new($file, 'r')) {
            my $cur_line = 0;
            while (my $line = <$fh>) {
                ++$cur_line;
                last if $cur_line > $end;
                next if $cur_line < $start;
                my @tag = $cur_line == $linenum ? qw(<b> </b>) : ("","");
                $code .= sprintf(
                    '%s%5d: %s%s',
                        $tag[0], $cur_line, html_escape($line), $tag[1],
                );
            }
        }
    }
    return $code;
}

sub html_escape {
    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/"/&quot;/g;
    return $str;
}

1;

=head1 NAME

CGI::Application::Plugin::DebugScreen - add Debug support to CGI::Application.

=head1 VERSION

This documentation refers to CGI::Application::Plugin::DebugScreen version 0.02

=head1 SYNOPSIS

  use CGI::Application::Plugin::DebugScreen;

Only it.
If 500 http's error is generated...

=head1 DESCRIPTION

This plug-in add Debug support to CGI::Application.
This plug-in like Catalyst debug mode.

When 'die' is generated by 'runmode',
 this plug-in outputs the stack trace by error_mode().
The error cannot be caught excluding runmode.

=head1 DEPENDENCIES

L<strict>

L<warnings>

L<CGI::Application>

L<HTML::Template>

L<Devel::StackTrace>

L<IO::File>

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>)
Patches are welcome.

=head1 SEE ALSO

L<strict>

L<warnings>

L<CGI::Application>

L<HTML::Template>

L<Devel::StackTrace>

L<IO::File>

=head1 Thanks To

MATSUNO Tokuhiro (MATSUNO)

Koichi Taniguchi (TANIGUCHI)

Masahiro Nagano (KAZEBURO)

=head1 AUTHOR

Atsushi Kobayashi, E<lt>nekokak@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Atsushi Kobayashi (E<lt>nekokak@cpan.orgE<gt>). All rights reserved.

This library is free software; you can redistribute it and/or modify it
 under the same terms as Perl itself. See L<perlartistic>.

=cut

