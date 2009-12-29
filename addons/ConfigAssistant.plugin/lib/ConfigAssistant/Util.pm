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
    my ($app, $plugin, $id) = @_;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();
    ###l4p $logger->info("Looking for option definition for option: $id");
    my @opt = ();
    # First, search the current template set's theme options
    my $set = $app->blog->template_set if $app->blog;
    if ( $set ) {
        my $set_opts       = MT->registry('template_sets')->{$set}->{options} || {};
        (my $set_id = $id) =~ s/^${set}_//; # Template set options are namespaced
        ###l4p $logger->info("Searching current template set for option: $set_id");
        @opt = map  { $set_opts->{$_} }
               grep { $set_id eq $_ } keys %$set_opts;
        ###l4p @opt && $logger->info("Found option in $set template set options using option ID: $set_id");
    }
    # Next, if a theme option was not found, search plugin options
    unless (@opt) {
        my $reg_opts = MT->registry('options') || {};
        my $reg_id   = lc($plugin->id).'_'.$id; # Template set options are namespaced
        ###l4p $logger->info("No theme option found, searching plugin options fpr $reg_id");
        ###l4p $logger->debug('Registry options $reg_opts: ', l4mtdump($reg_opts));
        @opt = map  { $reg_opts->{$_} }
               grep { $reg_id eq $_ } keys %$reg_opts;
    }
    if ( @opt > 1 ) {
        my $err = sprintf "Conflicting options found with option ID %s", $id;
        MT->log({
            message => $err,
            level   => MT::Log::ERROR(),
        });
        ###l4p $logger->error($err, l4mtdump( \@opt ));
        return;
    }
    elsif ( ! @opt ) {
        my $err = sprintf "No options found for option ID %s", $id;
        MT->log({
            message => $err,
            level   => MT::Log::ERROR(),
        });
        ###l4p $logger->error($err);
        return;
    }
    ###l4p $logger->info('Final $opt returned: ', l4mtdump(shift @opt));
    return shift @opt;
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
