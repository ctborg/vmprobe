package Vmprobe::Util;

use common::sense;

use Exporter 'import';
our @EXPORT = qw(pages2size colour);



sub term_dims {
    require Term::Size;

    my ($term_cols, $term_rows) = Term::Size::chars(*STDOUT{IO});

    $term_cols //= 80;

    return ($term_cols, $term_rows);
}


sub load_file {
    my $filename = shift;

    my $fh;

    if (!defined $filename || $filename eq '-') {
        $fh = \*STDIN;
        binmode $fh;
    } else {
        open($fh, '<:raw', $filename) || die "couldn't open $filename for reading: $!";
    }

    my $file;

    {
        local $/;
        $file = <$fh>;
    }

    return $file;
}



sub pages2size {
    use integer; ## FIXME: show a decimal place?

    my $pages = shift;
    my $pagesize = shift // 4096;

    $pages *= $pagesize;

    $pages /= 1024;
    return "${pages}K" if $pages < 1024;

    $pages /= 1024;
    return "${pages}M" if $pages < 1024;

    $pages /= 1024;
    return "${pages}G" if $pages < 1024;

    $pages /= 1024;
    return "${pages}T";
}


sub format_time {
    my $time = shift;

    if ($time < 1) {
      return sprintf("%.1fms", $time * 1000.0);
    }

    return sprintf("%.1fs", $time);
}



sub colour {
    my $text = shift;
    my $colour = shift;

    return $text if !-t STDOUT;

    require Term::ANSIColor;

    return Term::ANSIColor::colored($text, $colour);
}



sub is_valid_package_name {
    my $name = shift;

    return !!($name =~ m{\A\w+(?:::\w+)*\z});
}



sub capture_stderr (&@) {
    my ($code, @args) = @_;

    require Guard;

    open(my $old_err, '>&', \*STDERR) || die "can't dup STDERR: $!";

    Guard::scope_guard(sub {
        open(STDERR, ">&", $old_err) || die "couldn't restore STDERR: $!";
    });

    pipe(my $pipe_r, my $pipe_w) || die "can't pipe: $!";

    open(STDERR, '>&', $pipe_w) or die "Can't dup2: $!";

    $code->();

    return $pipe_r;
}




1;
