package ConfigAssistant::Util;

use strict;
use base 'Exporter';

our @EXPORT_OK = qw( find_theme_plugin find_template_def find_option_def find_option_plugin );

use MT::Log::Log4perl qw( l4mtdump ); use Log::Log4perl qw( :resurrect );
our $logger;

sub find_template_def {
    my ($id,$set) = @_;
    my $r      = MT->registry('template_sets');
    foreach my $type (qw(widget_sets widget index module individual system archive)) {
	if ($r->{$set}->{'templates'}->{$type}) {
	    my $def = $r->{$set}->{'templates'}->{$type}->{$id};
	    if ( $def ) {
		$def->{type} = $type;
		return $def;
	    }
	}
    }
    return undef;
}

sub find_option_def {
    my ($app,$id) = @_;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ###l4p $logger->info("Looking for option definition for option: $id");
    my $opt;
    # First, search the current template set's theme options
    if ($app->blog) {
        my $set = $app->blog->template_set;   # FIXME Needs default value
        $id =~ s/^($set)_//;
        ###l4p $logger->info("Searching template set $set for $id option");
        my $r = MT->registry('template_sets');
        ###l4p $logger->debug('Template set options $r: ', l4mtdump($r));
        if ($r->{$set}->{'options'}) { # FIXME Could error if $r or $r->{$set} are undefined.
            foreach (keys %{$r->{$set}->{'options'}}) {
                next unless $id eq $_;
                ###l4p $logger->info("Found template set option: $_");
                $opt = $r->{$set}->{'options'}->{$id}; # FIXME Clobbers any existing value
                ###l4p $logger->info('Set $opt: ', l4mtdump($opt));
            }
        }
    }
    # Next, if a theme option was not found, search plugin options
    unless ($opt) {
        ###l4p $logger->info('No theme option found, searching plugin options');
        my $r = MT->registry('options');
        ###l4p $logger->debug('Registry options $r: ', l4mtdump($r));
        if ($r) {
            foreach (keys %{$r}) {
                next unless $id eq $_;
                ###l4p $logger->info("Found MT registry option: $_");
                $opt = $r->{$id}; # FIXME Clobbers any existing value
                ###l4p $logger->info('Set $opt: ', l4mtdump($opt));
            }
        }
    }
    ###l4p $logger->info('Final $opt returned: ', l4mtdump($opt));
    return $opt;
}

sub find_theme_plugin {
    my ($set) = @_;
    for my $sig ( keys %MT::Plugins ) {
        my $plugin = $MT::Plugins{$sig};
        my $obj    = $MT::Plugins{$sig}{object};
        my $r      = $obj->{registry};
        my @sets   = keys %{ $r->{'template_sets'} };
        foreach (@sets) {
            return $obj if ( $set eq $_ );
        }
    }
    return undef;
}

sub find_option_plugin {
    my ($opt_name) = @_;
    for my $sig ( keys %MT::Plugins ) {
        my $plugin = $MT::Plugins{$sig};
        my $obj    = $MT::Plugins{$sig}{object};
        my $r      = $obj->{registry};
        my @opts   = keys %{ $r->{'options'} };
        foreach (@opts) {
            return $obj if ( $opt_name eq $_ );
        }
    }
    return undef;
}

1;
