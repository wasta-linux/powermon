#!/usr/bin/perl
# ftp uploader script for raspberry pi
# Copyright Paul Zwierzynski 2-3-2016 

# this script will look for .csv files not marked as executable
# compress them, and upload them to an ftp server
# then mark them executable when finished to keep track 
# csv files marked as executable (old files from previous system) are ignored


### below are the parameters you need to set ###

# your login username and password
# use a backslash before any @ signs like: user\@powermon.org
my $username = "#USERNAME#\@powermon.org";
my $password = "#PASSWORD#";

# These shouldn't need to be changed
# the ftp server name
my $ftpsite = "ftp.powermon.org";

# folder on the ftp server to put files in
my $folder = "/";

# look for and upload files from this directory on ipcop
my $directory = "/home/pi/power";

### end of variable definition  ###



use Net::FTP;
my $errormsg = '';



my $ftp = Net::FTP->new("$ftpsite", Debug => 1);
my $success = $ftp->login("$username", "$password");
if ($success != 1)
    {
    $errormsg = "FTP login failed";
    print $errormsg . "\n";

    exit;
    }
  


my $success = $ftp->cwd("$folder");
if ($success != 1)
    {
    print "Attempting to create $folder folder on ftp server.\n";

    my $create =  $ftp->CreateRemoteDir("$folder");
    if ($create != 1)
        {
        $errormsg = "Failed to create folder $folder on FTP server";
        print $errormsg . "\n";

        exit;
        }
    } else {
    my $success = $ftp->cwd("$folder");
    if ($success != 1)
        {
        $errormsg = "Could not CD into $folder on FTP server";
        print $errormsg . "\n";

        exit;
        }
    }

# set binary mode for bzip2 files
$ftp->binary();

my $count = 0;
opendir(DIR, "$directory");
my @files = readdir(DIR);
chdir("$directory");

foreach my $file (@files)
    {
    #print "found $file\n";
    #If file isn't in use and not marked executable compress and upload it
    if (-f $file && ($file =~ /\.csv/) && (not -x $file)) 
        {
        # if csv file has changed since midnight today, it is in use, don't compress it 
        if ((localtime((stat _)[9]))[3] != (localtime)[3] )
            {
            if ($file !~ /\.bz2/)
                {
                system( "/bin/bzip2 $file" );
                $file .= "\.bz2"
                }
            # upload the file
            print "attempting upload of $file\n";
            $ftp->put("$file")
            or die "Could not put the file on the server ", $ftp->message;
            $count++;
            #Mark file as executable so it won't be uploaded again next time
            chmod(0755, "$directory\/$file");
            } else {
            print "skipping compression and upload of $file  It looks like it was modified today.\n";
            }
        }
    }

$ftp->quit();

if ($count)
    {
    print "$count files uploaded to ftp server.\n";
    } else {
    print "No files waiting to be uploaded to ftp server.\n";
    }


