use v6;
use Test;

plan 36;

# L<S32::IO/Functions/spurt>

my $path = "tempfile-spurt-test";

# filename as str tests
all-basic({ $path });

# filename as IO tests
all-basic({ $path.IO });

sub all-basic(Callable $handle) {
    my Blob $buf = "hello world".encode("utf-8");
    my $txt = "42";

    spurt $handle(), $buf; 
    is slurp($path, :bin), $buf, "spurting Buf ok";

    spurt $handle(), $txt;
    is slurp($path), $txt, "spurting txt ok";

    spurt $handle(), $txt, :enc("ASCII");
    is slurp($path), $txt, "spurt with enc";

    spurt $handle(), $buf;
    spurt $handle(), $buf, :append;
    is slurp($path, :bin), ($buf ~ $buf), "spurting Buf with append";

    spurt $handle(), $txt;
    spurt $handle(), $txt, :append;
    is slurp($path), ($txt ~ $txt), "spurting txt with append";
    
    unlink $path;

    lives-ok { spurt $handle(), $buf, :createonly }, "createonly creates file with Buf";
    ok $path.IO.e, "file was created";
    dies-ok { spurt $handle(), $buf, :createonly }, "createonly with Buf fails if file exists";
    unlink $path;

    lives-ok { spurt $handle(), $txt, :createonly }, "createonly with text creates file";
    ok $path.IO.e, "file was created";
    dies-ok { spurt $handle(), $txt, :createonly }, "createonly with text fails if file exists";
    unlink $path;
}

# Corner cases
{
    # Spurt on open file
    {
        spurt $path, "42";
        is slurp($path), "42", 'can spurt into an open file';
    }

    # Buf into an open non binary file
{
        my Buf $buf = Buf.new(0xC0, 0x01, 0xF0, 0x0D);
        spurt $path, $buf;
        is slurp($path, :bin), $buf, 'can spurt a Buf into an open handle';
}

    # Text into a open binary file
{
        my Str $txt = "Bli itj nå trønder-rock uten tennis-sokk";
        spurt $path, $txt;
        is slurp($path), $txt, 'can spurt text into a binary handle';
}

    # spurting to a directory
    {
        dies-ok { open('t').spurt("'Twas brillig, and the slithy toves") },
            '.spurt()ing to a directory fails';
        dies-ok { spurt('t', 'Did gyre and gimble in the wabe') },
            '&spurt()ing to a directory fails';
    }

    unlink $path;
}


# IO::Handle spurt
{
    $path.IO.spurt("42");
    is slurp($path), "42", "IO::Handle slurp";

    my Blob $buf = "meow".encode("ASCII");
    $path.IO.spurt($buf);
    is slurp($path, :bin), $buf, "IO::Handle binary slurp";
    
    dies-ok { $path.IO.spurt("nope", :createonly) }, "IO::Handle :createonly dies";
    unlink $path;
    lives-ok { $path.IO.spurt("yes", :createonly) }, "IO::Handle :createonly lives";
    ok $path.IO.e, "IO::Handle :createonly created a file";
    
    # Append
    {
        my $io = $path.IO;
        $io.spurt("hello ");
        $io.spurt("world", :append);
        is slurp($path), "hello world", "IO::Handle spurt :append";
    }

    # Not append!
    {
        my $io = $path.IO;
        $io.spurt("hello ");
        $io.spurt("world");
        is slurp($path), "world", "IO::Handle not :append";
    }

    # encoding
    {
        my $t = "Bli itj nå fin uten mokkasin";
        $path.IO.spurt($t, :enc("utf8"));
        is slurp($path), $t, "IO::Handle :enc";
    }
    unlink $path;
}

CATCH {
    unlink $path;
}

if $path.IO.e {
    say "Warn: '$path shouldn't exist";
    unlink $path;
}

# RT #126006
{
    given 'temp-file-RT-126006-test'.IO {
        LEAVE .unlink;
        when .e { flunk "ABORT: cannot run test while file `$_` exists"; }

        .spurt: 'something';
        is .e, True, 'for non-existent file after spurting, .e says it exists';
    }
}
