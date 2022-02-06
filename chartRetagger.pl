################
# Chart retagger
# - dr3v
################

############################
# Get list of song.ini files
$iniList = (`dir /s/b *song.ini`); chomp $iniList;
@iniFiles = split("\n",$iniList);

###########################################
# Create backups of song.inis, just in case
foreach(@iniFiles){
    $file = $_;
    $dir = $file;
    $dir =~ s/^(.*\\).*/\1/g;

    ## debug
    # print $dir . "\n";

    `copy "$file" "$dir\\song.bak.ini"`;
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

        push(@fields,$thisValues[0]);
        push(@values,$thisValues[1]);
    }
}

#######
# Debug
# foreach(@fields){
#     print $_. "\n";
#}

######################################
# Ask user what they're trying to edit
FIELDASK:

print("What field do you want to edit?\n");

$editField = <STDIN>; chomp $editField;

###############################################
# Tell them they are wrong if they type a value
# that doesn't match an identified field
if (grep {m/^$editField$/} @fields){
    print ("yep!");
} else {
    print($editField . " is not a valid field.. try again!\n");
    goto FIELDASK;
}

# Main
sub mainRoutine(){

    foreach(@iniFiles){

    }
}

sub exit(){
    print "Ending program";
    exit;
}