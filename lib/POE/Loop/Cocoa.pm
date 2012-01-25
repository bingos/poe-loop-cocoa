package POE::Loop::Cocoa;

#ABSTRACT: Cocoa event loop support for POE

use strict;
use warnings;

use POE::Loop::PerlSignals;

# Everything plugs into POE::Kernel.
package # Hide from Pause
  POE::Kernel;

use strict;
use warnings;
use Cocoa::EventLoop;

my $loop;
my $_watcher_timer;
my $_idle_timer;
my %signal_watcher;
my %handle_watchers;

sub loop_initialize {
}

sub loop_finalize {
}

sub loop_do_timeslice {
  Cocoa::EventLoop->run_while(0.1)
}

sub loop_run {
  my $self = shift;

  # Avoid a hang when trying to run an idle Kernel.
  $self->_test_if_kernel_is_idle();

  while ($self->_data_ses_count()) {
    $self->loop_do_timeslice();
  }
}

sub loop_halt {
}

sub loop_watch_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  if ($mode == MODE_RD) {

  $handle_watchers{watch_r}{$handle} = Cocoa::EventLoop->io(
      fh   => $handle,
      poll => 'r',
      cb   =>
        sub {
          my $self = $poe_kernel;
          if (TRACE_FILES) {
            POE::Kernel::_warn "<fh> got read callback for $handle";
          }
          $self->_data_handle_enqueue_ready(MODE_RD, $fileno);
          $self->_test_if_kernel_is_idle();
          return 0;
        },
    );

  }
  elsif ($mode == MODE_WR) {

  $handle_watchers{watch_w}{$handle} = Cocoa::EventLoop->io(
      fh   => $handle,
      poll => 'w',
      cb   =>
        sub {
          my $self = $poe_kernel;
          if (TRACE_FILES) {
            POE::Kernel::_warn "<fh> got write callback for $handle";
          }
          $self->_data_handle_enqueue_ready(MODE_WR, $fileno);
          $self->_test_if_kernel_is_idle();
          return 0;
        },
    );

  }
  else {
    confess "Cocoa::EventLoop::io does not support expedited filehandles";
  }
}

sub loop_ignore_filehandle {
  my ($self, $handle, $mode) = @_;
  my $fileno = fileno($handle);

  if ( $mode == MODE_EX ) {
    confess "Cocoa::EventLoop::io does not support expedited filehandles";
  }

  delete $handle_watchers{ $mode == MODE_RD ? 'watch_r' : 'watch_w' }{$handle};
}

sub loop_pause_filehandle {
  shift->loop_ignore_filehandle(@_);
}

sub loop_resume_filehandle {
  shift->loop_watch_filehandle(@_);
}

sub loop_resume_time_watcher {
  my ($self, $next_time) = @_;
  return unless defined $next_time;
  $next_time -= time();
  $next_time = 0 if $next_time < 0;
  $_watcher_timer = Cocoa::EventLoop->timer( after => $next_time, cb => \&_loop_event_callback);
}

sub loop_reset_time_watcher {
  my ($self, $next_time) = @_;
  undef $_watcher_timer;
  $self->loop_resume_time_watcher($next_time);
}

sub _loop_resume_timer {
  undef $_idle_timer;
  $poe_kernel->loop_resume_time_watcher($poe_kernel->get_next_event_time());
}

sub loop_pause_time_watcher {
}

# Event callback to dispatch pending events.

sub _loop_event_callback {
  my $self = $poe_kernel;

  $self->_data_ev_dispatch_due();
  $self->_test_if_kernel_is_idle();

  undef $_watcher_timer;

  # Register the next timeout if there are events left.
  if ($self->get_event_count()) {
    $_idle_timer = Cocoa::EventLoop->timer( cb => \&_loop_resume_timer );
  }

  return 0;
}
1;

=begin poe_tests

sub skip_tests {
  $ENV{POE_EVENT_LOOP} = "POE::Loop::Cocoa";
  return;
}

=end poe_tests

=pod

=head1 SYNOPSIS

See L<POE::Loop>.

=head1 DESCRIPTION

POE::Loop::Cocoa implements the interface documented in POE::Loop.
Therefore it has no documentation of its own. Please see POE::Loop for more details.

=head1 SEE ALSO

L<POE>

L<POE::Loop>

L<Cocoa::EventLoop>

=cut
