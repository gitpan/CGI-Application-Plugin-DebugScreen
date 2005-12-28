package DebugScreen::Test;

use Test::More tests => 1;

use base qw(CGI::Application);
use_ok('CGI::Application::Plugin::DebugScreen');

1;
