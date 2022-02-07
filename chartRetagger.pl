################################
# Chart retagger - dr3v
#####
# To-do:
# x alter backup logic to only backup files queued for editing!!!
# xxxx leave logic in to take "latestBackup" if it doesn't already exist, couldn't hurt
# x add communication about initial backup files...
# x add communication about which files are going to be edited before committing
# x research/resolve genre names with spaces between each char?
# xxxx it's something to do with file encoding.. list prints fine now, idk if all errors are resolved.
# x investigate + fix "file/dir" incorrect errors when reading files
# x allow multiple-value entry for editable field values
# - create restore-backup routine
# - allow user to edit one field based on a search for another (i.e. edit all "genre" tags for a single artist)
################################
use Win32::Console::ANSI;
use Term::ANSIColor;
use File::Copy;

print color('reset');

################
# Misc vars/options
@exitP = ('x','exit','bye','quit');
$debugMode = 0;

############################
# Get list of song.ini files
clearScr();
green("Creating backups for all song.ini files without an existing backup...\nThis may take a minute...\n\n");

$iniList = (`dir /s/b *song.ini`); chomp $iniList;
@iniFiles = split("\n",$iniList);

###########################################
# Create backups of all song.ini files, just in case

if($debugMode){
    open(LOGFILE,">","chartRetagger.log");
}

foreach(@iniFiles){
    $file = $_;
    $dir = $file;
    $dir =~ s/^(.*\\).*/\1/g;

    # let's use the epoch as a unique value...
    $epoch = time();

    ## debug
    # print $dir . "\n";

    if($debugMode){
        print LOGFILE ("Found song.ini: $file\n");
    };

    # If an "originalBackup" file doesn't exist, make one
    if(-e "$dir\\song.originalBackup.ini"){
        # don't do anything
    } else {
        
        #####
        # cmd method.. doesn't like weird chars because this shit is ANSI
        if(-e $file){
            `copy "$file" "$dir\\song.originalBackup.ini"`;
        } else {
            errorFile($file);
        }

        ####################
        # File:::Copy method
        # my $oldFile = ("$file");
        # my $newFile = ("$dir\\song.originalBackup.ini");
        # copy("$oldFile","$newFile");

        if($debugMode){
            print LOGFILE ("\nTrying to copy:\n\t$file\nTo:\n\t$dir\n\n");
        }

        print LOGFILE ("Error: $!\n\n");

    };
}


# If there's a problem file, let the user know
if(-e "errorFiles.log"){
    open(ERRORFILE,"<","errorFiles.log");
    while(<ERRORFILE>){
        $fileLine = $_; chomp $fileLine;
        push(@errorFileLines,$fileLine);
    }
    close ERRORFILE;
}

sub errorFile {

    if(-e "errorFiles.log"){
        # nothin
    } else {
        open(ERRORFILE,">","errorFiles.log");
        close ERRORFILE;
    }

    my $file = $_[0]; chomp $file;

    push(@errorFileLines,$file);
}


if(@errorFileLines){
    # DEBUG
    # print("\n\n----------------\n\n");
    # foreach(@errorFileLines){
    #     print "$_\n";
    # };
    # print("\n\n----------------\n\n");

    @errorFileLines = uniq(@errorFileLines);
    @errorFileLines = sort(@errorFileLines);


    @errorFileLines = grep {/\S/} @errorFileLines;

    $strErrorFiles = join("\n",@errorFileLines);
    chomp $strErrorFiles;

    open(ERRORFILE,">","errorFiles.log");
    print ERRORFILE ($strErrorFiles);
    close ERRORFILE;

    $errorFileNum = @errorFileLines;

    red("There are $errorFileNum files that can not be backed up or edited...\n");
    red("See 'errorFiles.log' for list of known files that this script can't handle.\n");
};

########
## debug
# print $iniList;

################
# Declare arrays
@fields = ();
@values = ();

##########################################
# check the fields and values of ini files
foreach(@iniFiles){
    @thisValues = ();
    open(INI,'<',$_);
    while(<INI>){
        my $line = $_; chomp $line;
        if($line =~ m/^.*=.*$/){
            @thisValues = split(/\s*=\s*/,$line);
        }

        chomp $thisValues[0];
        chomp $thisValues[1];

        # DEBUG
        # print ("$thisValues[0] - $thisValues[1]\n");
        # print ("$thisValues[0]\n");
        # open(OUTFILE,">>","ass.txt");
        # print OUTFILE ("$thisValues[0] - $thisValues[1]\n");
        # close OUTFILE;

        push(@fields,$thisValues[0]);
        push(@values,$thisValues[1]);
    }
}

#########################################################
# Create a master list array of strings for field - value
$ct = 0;
@allFieldValues = ();
foreach(@fields){
    my $field = $_; # print $field . "\n";
    my $val = $values[$ct];

    $fieldValStr = ("$field: $val");

    # DEBUG
    # print("$fieldValStr\n");
    # open(OUTFILE,">>","ass.txt");
    # print OUTFILE ("$fieldValStr\n");
    # close OUTFILE;

    push(@allFieldValues,$fieldValStr);
    $ct += 1;
}

# Use uniq sub to make master field - values
@masterValues = uniq(@allFieldValues);

#######
# DEBUG
# foreach(@masterValues){
    # print $_ . "\n";
# }

##########################
# Convert to unique values
sub uniq {
    # my %seen;
    # return grep {!$seen{$_}++} @_;

    my %seen;
    my @uniqueVals = (grep {!$seen{$_}++} @_);
    return @uniqueVals;
}

#######
# Debug
# foreach(@fields){
#     print $_. "\n";
#}

######################################
# Ask user what they're trying to edit
print("\n");

STARTPROG:

green("Welcome to chartRetagger! Enter 'exit/bye/x/quit' at any ");
blue("input prompt ");
green("to quit the program.\nPress ENTER to show list of editable chart fields.\n");

$welcomeRes = (<STDIN>); chomp $welcomeRes;

####################################
# Cleaning process... this is a mess
@cleanFields = grep {/\S/} @fields;

@uniqueFields = uniq(@cleanFields);
@uniqueFields = sort(@uniqueFields);

@uniqueFieldsCleaned = ();
foreach(@uniqueFields){
    my $thisVal = $_; chomp $thisVal;
    $thisVal =~ s/\0//g;
    $thisVal =~ s/\s//g;
    chomp $thisVal;
    push(@uniqueFieldsCleaned,$thisVal);
}

@uniqueFieldsCleaned = uniq(@uniqueFieldsCleaned);
@uniqueFieldsCleaned = sort(@uniqueFieldsCleaned);

$availableFields = join("\n",@uniqueFieldsCleaned); chomp $availableFields;

####################################
FIELDASK:

green("These are the available fields to edit:\n\n");

print($availableFields . "\n");

    # DEBUG
    # open(TEST,">",$epoch . "ass.txt");
    # print TEST $availableFields;
    # close TEST;

blue("\nWhat field do you want to edit? ");

$editField = <STDIN>; chomp $editField;

###############################################
# Tell them they are wrong if they type a value
# that doesn't match an identified field
if (grep {m/^$editField$/} @fields){
    # mainRoutine($editField);
    clearScr();
} elsif (grep {m/$editField/} @exitP){
    exitSub();
} else {
    clearScr();
    red("\n" . '"' . $editField . '"' . " is not a valid field.. try again! (enter 'x/exit/quit/bye' to exit script)\n\n");
    goto FIELDASK;
}

####################################
# Ask what value they want to change
@matchedVals = grep(/^$editField/,@masterValues);

# sort vals
@matchedVals = sort @matchedVals;
$matches = join("\n",@matchedVals);

# split genres and make array of valid values
@validVals = ();
foreach(@matchedVals){
    my @split = split(": ",$_);
    push(@validVals,$split[1]);
};

# DEBUG
# $valstest = join("\n",@validVals);
# print $valstest;

VALUEASK:
green("\nThese are the values from all songs that matched your field search:\n\n");

print($matches);

blue("\n\nSpecify the values you would like to change (case sensitive, separated by commas): ");

$editValue = (<STDIN>); chomp $editValue;

@editList = split(/,\s*/,$editValue);
$editValueSearch = join("|",@editList);

# DEBUG
# print("\n\ntest val:$editValue\n\n");

# Check if request is valid
@editList = grep{m/^$editValueSearch$/} @validVals;
$validSearch = join(", ",@editList);

if(grep {m/$editValue/} @exitP){
    exitSub();
} elsif (@editList == 0) {
    clearScr();

    red("\nYou did not enter any valid ");
    blue("$editField ");
    red("values. Try again!\n");
    goto VALUEASK;
} else {
    # we're good
    green("\nThese are the values you're going to change: ");
    yellow("$validSearch. ");

    # Go fetch song list and then ask user to confirm in the section that follows
    printSongs($editField,$editValueSearch);

    # blue("\n\nProceed (y/n)? ");

    # my $continue = (<STDIN>); chomp $continue;
    
    # if(grep {m/^$continue$/} @exitP){
    #     exitSub();
    # } elsif ($continue eq "n"){
    #     clearScr();
    #     goto VALUEASK;
    # } else {
    #     printSongs($editField,$editValueSearch);
    #     # green("");
    # };
}

###################################
# Look up songs we're about to edit
sub printSongs {

    my $iniList = (`dir /s/b *song.ini`); chomp $iniList;
    my @iniFiles = split("\n",$iniList);

    my $field = $_[0];
    my $valueSearch = $_[1];

    @songsToEdit = ();

    foreach(@iniFiles){
        my $editing = 0;
        my $iniFile = $_;
        my @thisFileLines = ();
        
        open(THISFILE,"<",$iniFile);
        
        while(<THISFILE>){
            my $line = $_; chomp $line;
            push(@thisFileLines,$line);
        }

        # If the file contains likes with our desired field and any of our values, we flag it
        if(grep {m/$field\s*=\s*$valueSearch/} @thisFileLines){
            $editing = 1;
        }

        # If we're editing this song, let's inform the user
        if($editing){
            # Make array of just the fields we want to display to the user
            @artistSong = grep {m/^\s*(artist|genre|name)/} @thisFileLines;
            @artistSong = sort(@artistSong);

            $artist = $artistSong[0];
            $genre = $artistSong[1];
            $title = $artistSong[2];

            # print $artistSong[0] . "\n";

            $artist =~ s/^.*artist\s*=\s*(.+)$/\1/g; chomp $artist;
            $title =~ s/^.*name\s*=\s*(.+)$/\1/g; chomp $title;
            $genre =~ s/^.*genre\s*=\s*(.+)$/\1/g; chomp $genre;

            push(@songsToEdit,"($genre) $artist - $title");
            # print("$artist - $title\n");
        }

    }

    my $songEditList = join("\n",@songsToEdit);

    green("\n\nThese are the songs that will be affected:\n\n");
    yellow("$songEditList\n\n");

}

####################################
# Ask if user wants to proceed after seeing what they're changing
blue("Proceed (y/n)? ");
my $continue = (<STDIN>); chomp $continue;

if(grep {m/^$continue$/} @exitP){
    exitSub();
} elsif ($continue eq "n" || $continue eq "no"){
    clearScr();
    goto VALUEASK;
} else {
    # Continue
};

##########
# Ask what to replace the current values with
blue("\nReplace ");
yellow($validSearch);
blue(" with (single value): ");

$replaceValue = (<STDIN>); chomp $replaceValue;

if(grep {m/^$replaceValue$/} @exitP){
    exitSub();
};

print("\n");

ASKFINAL:

green("You're about to replace all ");
yellow("$editField ");
green("values matching ");
yellow("$validSearch ");
green("in your song.ini files with ");
yellow("$replaceValue...\n\n");

# aight
blue("Is this OK (y/n)? ");

$finalConfirm = (<STDIN>); chomp $finalConfirm;

if($finalConfirm eq "n" || $finalConfirm eq "no"){
    exitSub();
} elsif ($finalConfirm eq "y" || $finalConfirm eq "yes") {
    # proceed

    # DEBUG
    # print("\n\nfield: $editField\nold value: $editValue\nnew value: $replaceValue\n\n");

    editSongs($editField,$validSearch,$replaceValue);
} else {
    red("\n" . '"' . $finalConfirm . '"' . " is not a valid response! Try again.\n\n");
    goto ASKFINAL;
}

#######################################
# Edit the values
sub editSongs {
    # DEBUG
    # print("Works!\n\n");

    # Establish args as vars
    my $field = $_[0];
    my $oldValue = $_[1];
    my $newValue = $_[2];

    # DEBUG
    # print("\n\n$field\n$oldValue\n$newValue\n\n");

    ############################
    # Get list of song.ini files again for some reason I can't understand
    my $iniList = (`dir /s/b *song.ini`); chomp $iniList;
    my @iniFiles = split("\n",$iniList);

    @alteredFiles = ();

    # Split multiple values
    $oldValueSearch = join("|",@editList);

    foreach(@iniFiles){
        $file = $_; chomp $file;

        $dir = $file;
        $dir =~ s/^(.*\\)(.*)/\1/g;

        $fileName = $file;
        $fileName =~ s/^(.*\\)(.*)/\2/g;

        # DEBUG
        # print("File: $file\n");
        # print("Dir: $dir\n");

        open(SONG,'<',"$file");

        @fileContentArray = ();
        while(<SONG>){
            chomp $_;
            push(@fileContentArray,$_);
        };

        $fileContents = join("\n",@fileContentArray); chomp $fileContents;

        close SONG;

        #######################################################
        # if file matches field+previous value, let's update it
        if($fileContents =~ m/($field\s*=\s*)($oldValueSearch)/){
            # we're editing this
            push(@alteredFiles,$file);

            $backupFile = ("$dir\\song.bak$epoch.ini");
            open(BACKUP,">",$backupFile);

            print BACKUP ($fileContents);

            # make the change
            $fileContents =~ s/($field\s*=\s*)$oldValue/\1$newValue/g;

            unlink($file);

            open(NEWSONG,">",$file);
            print NEWSONG $fileContents;
            close NEWSONG;
        }

    }
        #######################################################

    green("\nFinished!\n\n");

    $updatedFiles = (join("\n",@alteredFiles));
    chomp $updatedFiles;

    green("Updated files:\n");
    yellow($updatedFiles . "\n");

    #########################
    # Ask to edit more songs
    # This part doesn't really work... so I turned it off.. 

    # green("Do you want to edit more songs (y/n)? ");

    # $continue = (<STDIN>); chomp $continue;

    # if($continue eq "y" || $continue eq "yes"){
    #     clearScr();
    #     print("\n");
    #     goto STARTPROG;
    # } else {
    #     exitSub;
    # }

    exitSub();

}

sub exitSub(){

    if($debugMode){
        close LOGFILE;
    }

    green("\nGoodbye!\n");
    exit;
}


###############################
# Color subs - don't work with odd characters in windows console.. will try to fix at some point
sub green {
    my $message = $_[0];

    print color('green');
    print ($message);
    print color ('reset');
}

sub red {
    my $message = $_[0];

    print color('red');
    print ($message);
    print color ('reset');
}

sub blue {
    my $message = $_[0];

    print color('bright_blue');
    print ($message);
    print color ('reset');
}

sub yellow {
    my $message = $_[0];

    print color('yellow');
    print ($message);
    print color ('reset');
}

sub clearScr (){
    #clear the screen
    
    if($debugMode){
        # don't do it
    } else {
        print "\033[2J";
    }

}