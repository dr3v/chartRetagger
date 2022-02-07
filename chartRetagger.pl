################################
# Chart retagger - dr3v
#####
# To-do:
# x alter backup logic to only backup files queued for editing!!!
# xxxx leave logic in to take "latestBackup" if it doesn't already exist, couldn't hurt
# x add communication about initial backup files...
# - add communication about which files are going to be edited before committing
# - research/resolve genre names with spaces between each char?
# - investigate + fix "file/dir" incorrect errors when reading files
# x allow multiple-value entry for editable field values
################################
use Win32::Console::ANSI;
use Term::ANSIColor;

print color('reset');

################
# Misc vars/options
@exitP = ('x','exit','bye','quit');
$debugMode = 1;

############################
# Get list of song.ini files
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
        `copy "$file" "$dir\\song.originalBackup.ini"`;
    };
}

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
        if($_ =~ m/^.*=.*$/){
            chomp $_;
            @thisValues = split(/\s*=\s*/,$_);
        }

        # DEBUG
        # print ("$thisValues[0] - $thisValues[1]\n");
        # print ("$thisValues[0]\n");

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
    my %seen;
    return grep {!$seen{$_}++} @_;
}

#######
# Debug
# foreach(@fields){
#     print $_. "\n";
#}

######################################
# Ask user what they're trying to edit
clearScr();

print("\n");

STARTPROG:

green("Welcome to chartRetagger! Enter 'exit/bye/x/quit' at any ");
blue("input prompt ");
green("to quit the program.\nPress ENTER to show list of editable chart fields.\n\n");

$welcomeRes = (<STDIN>); chomp $welcomeRes;

@uniqueFields = uniq(@fields);
@uniqueFields = sort @uniqueFields;

$availableFields = (join("\n",@uniqueFields)); chomp $availableFields;

FIELDASK:

green("These are the available fields to edit: \n");

print($availableFields . "\n");

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
    blue("\n\nProcede (y/n)? ");

    my $continue = (<STDIN>); chomp $continue;
    
    if(grep {m/^$continue$/} @exitP){
        exitSub();
    } elsif ($continue eq "n"){
        clearScr();
        goto VALUEASK;
    } else {
        # green("");
    };

}

##################
# Backup the file?


##########
# Ask what to replace the current value with
blue("\nReplace ");
yellow($validSearch);
blue(" with (single value): ");

$replaceValue = (<STDIN>); chomp $replaceValue;

if(grep {m/$replaceValue/} @exitP){
    exitSub();
};

print("\n");

# green("You're about to replace all '$editField' values matching " . '"' . $editValue . '"' . " in your song.ini files with " . '"' . $replaceValue . '"...' . "\n\n");

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