use strict;
use warnings;
use ExtUtils::MakeMaker;
use POE::Test::Loops;

# Switch to default behavior if STDIN isn't a tty.

unless (-t STDIN) {
  warn(
    "\n",
    "=============================================\n\n",
    "STDIN is not a terminal.  Assuming --default.\n\n",
    "=============================================\n\n",
  );
  push @ARGV, "--default";
}

# Remind the user she can use --default.

unless (grep /^--default$/, @ARGV) {
  warn(
    "\n",
    "=============================================\n\n",
    "Prompts may be bypassed by running:\n",
    "   $^X $0 --default\n\n",
    "=============================================\n\n",
  );
}

# Should we skip the network tests?

my $prompt = (
  "Some of POE::Loop::Cocoa's tests require a\n" .
  "functional network.  You can skip these network\n" .
  "tests if you'd like.\n\n" .
  "Would you like to skip the network tests?"
);

my $ret = "n";
if (grep /^--default$/, @ARGV) {
  print $prompt, " [$ret] $ret\n\n";
}
else {
  $ret = prompt($prompt, "n");
}

my $marker = 'run_network_tests';
unlink $marker;
unless ($ret =~ /^Y$/i) {
  open(TOUCH,"+>$marker") and close TOUCH;
}

print "\n";

POE::Test::Loops::generate( 't', [ 'POE::Loop::Cocoa' ], 1 );

WriteMakefile(
  NAME            => 'POE::Loop::Cocoa',
  AUTHOR          => 'Chris Williams <chris@bingosnet.co.uk>',
  ABSTRACT        => 'Cocoa event loop support for POE.',
  VERSION_FROM    => 'lib/POE/Loop/Cocoa.pm',
  clean           => { FILES => 't/poe_loop_cocoa/*.t t/poe_loop_cocoa ' . $marker },
  test            => { TESTS => 't/*.t t/poe_loop_cocoa/*.t' },

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'POE::Test::Loops'    => 1.035,
  },

  META_MERGE      => {
    build_requires => {
      'POE::Test::Loops'    => 1.035,
    },
  },

  PREREQ_PM       => {
    'POE'               => 1.289,
    'Cocoa::EventLoop'  => 0.04,
  },
);

1;
