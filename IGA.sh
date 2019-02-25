#!/bin/bash

#IGA program - works in 3 modes
#1) setting a random wallpaper from the base
#2) intelligent wallpaper selection
#3) adding a wallpaper to the base

#Iga is based on 2 files and Wallpaper dir:
#1) KEYS_FILE - list of available key values (examplee - NATURE)
#2) IMAGE_KEYS_FILE - list of key values connected with wallpapers (example - forest.png NATURE)
#3) WALLPAPERS_DIR_PATH - place where wallpapers are hold

#Basing on user's answers to the questions, IGA chooses the wallpaper that contains the most of the key values that come from user's answers
#CONSTANT


DIR=$(dirname "$(readlink -f "$0")") #current path to the directory where the script is located
IMAGE_KEYS_FILE="image_keys.txt" #file with list of key values connected with wallpapers
IMAGE_KEYS_FILE_PATH="$DIR/$IMAGE_KEYS_FILE"
BUFF_FILE="buffer.txt" # all matched wallpapers (with repetitions)
RESULT_FILE="result.txt" #all matched wallpapers (sorted without repetitions)
FINAL_FILE="final.txt" #wallpaper that occured the most frequently (if more with the same number of repetitions than it holds more wallpapers and then one of them is chosen randomly)
SELECTED_FILE="selectedfinal.txt"
#WALLPAPERS_DIR_PATH_FILE="file:///home/szymon/Pulpit/projektSO/Wallpapers" #path to the dir with wallpapers
WALLPAPERS_DIR_PATH="$DIR/Wallpapers"
FILE_PREFIX="file://"
KEYS_FILE="keys.txt" #file with available key values
KEYS_PATH="$DIR/$KEYS_FILE"
TYPE1="\.png"
TYPE2="\.jpg"
FLAG_IF_CHOSEN=0; #hold info if and wallpaper has been chosen well
ITERATOR=0
#FUNCTIONS

#GENERATE A QUESTION
# INPUT: 1$ - question, 2$ - key value when user's answer is YES, 3$ - key value when NO
function generate_question(){
   zenity --question --text="$1?\n"
      case $? in 
         0) 
            RETURN=$2
            ;; 
         1) 
            RETURN=$3
            ;; 
         *) 	
            zenity --warning --text "An unexpected eror has occured!"
            exit
            ;; 
      esac
   CATEGORIES[$ITERATOR]="$RETURN"; #holds all chosen key values
   #echo ${CATEGORIES[$ITERATOR]}
   ITERATOR=`expr $ITERATOR + 1`;
}

function choose() { #CHOOSE A PHOTO TO BE UPLOADED TO THE APPLICATION
   FLAG_IF_CHOSEN=0; #reset variable which holds information if the file choosing ended succesfully
   FILE="$(zenity --file-selection --title='Select a File')";
   case $? in
      0)
      ;;
      1)
         zenity --question \
         --title="Cancel was made" \
         --text="File wasn't selected. Do You want to try again?"
         case $? in 
            0) 
               choose
               return 1;
            ;; 
            1) 
               return 1;
            ;; 
            *) 	
               zenity --warning --text "An unexpected error has occurred.";
               exit;
               ;; 
         esac
      ;;
                         
      *)
         zenity --warning --text "An unexpected error has occurred.";
         exit;
   esac

   FILE_NAME="$(echo $FILE | sed "s#.*/##")"; #get rid of the path
   #CHECK TYPE COMPATIBILITY
   if echo $FILE_NAME | grep "$TYPE1" >> $SELECTED_FILE || echo $FILE_NAME | grep "$TYPE2" >> $SELECTED_FILE
   then
      zenity --info --text "File has a good extension"
   else
      zenity --warning --text "File type is not jpg/png!"
      choose
      return 1;	
   fi
   rm $SELECTED_FILE;
   FILE_TYPE="$(echo $FILE | cut -d '.' -f 2)"; #get rid of name
   #get rid of the extension
   FILE_NAME_ONLY="$(echo $FILE_NAME | cut -d '.' -f 1)";
   #echo $FILE_NAME;
   #CHECK IF FILE NAME DOESN'T OCCUR IN THE FILE WITH WALLPAPERS AND KEY VALUES
  
   FLAG=0;
   if [ ! -f "$WALLPAPERS_DIR_PATH/$FILE_NAME" ] ; then 
      FLAG=1;
      if ! grep $FILE_NAME $KEYS_FILE ; then
         FLAG=1;
      else
         FLAG=0;
      fi
   else
      FLAG=0;
   fi


   if [[ $FLAG -eq 1 ]]  ; then
      zenity --info --text "Nice, you added a wallpaper!"
   else
      zenity --warning --text "The file exists. Pick another file"
      choose
      return 1;
   fi
   FLAG_IF_CHOSEN=1;
}

#GETOPTS OPTIONS

while getopts hvf:q OPT; do
   case $OPT in
      h) zenity --info --title "Help" --height 100 --text "Availabale options: h,v - version,q - license";
         exit;;
      v) zenity --info --title "Version" --text "Version: 1.0. Author: Szymon Pietkun";
         exit;;
      q) zenity --info --title "License" --text "SHAREWARE"; 
         exit;;
      *) zenity --error --title "Option known" --text "Sorry, the option is inavailable";
         exit;;
		
      esac
done

#CHECK FILES AND DIRS PRESENCE
if [ ! -f $KEY_FILE ]; then
   zenity --error --text "Key file is missing. Sorry";
   exit;
fi

if [ ! -d $WALLPAPERS_DIR_PATH ]; then
   mkdir -p $WALLPAPERS_DIR_PATH;
fi

#MENU

MENU=("Random wallpaper" "Intelligent wallpaper set" "Add wallpaper to the base")
MENU_OPTION=$(zenity  --list  --title "INTELLIGENT GRAPHIC ASSISTENT" --text "Choose a mode" --column "options" "${MENU[@]}");

case $MENU_OPTION in
   ${MENU[0]}) #RANDOM WALLPAPER

      ALL_WALLPAPERS=("$WALLPAPERS_DIR_PATH"/*); #put all wallpapers to the array
      #for i in "${ALL_WALLPAPERS[@]}";
      #do
         #echo "$i";
      #done
      NUMBER_OF_ALL=${#ALL_WALLPAPERS[@]};
      if [[ $NUMBER_OF_ALL -eq 0 ]]; then # check if there are wallpapers in the base
         zenity --warning --text "There are no wallpapers in the base. Please, load some of them first.";
         exit;
      else 
         RANDOM_N_WALLPAPER=$(( ( RANDOM % $NUMBER_OF_ALL )  )); #if there are wallpapers, draw one of them
         gsettings set org.gnome.desktop.background picture-uri "$FILE_PREFIX${ALL_WALLPAPERS[$RANDOM_N_WALLPAPER]}"
         gsettings set org.gnome.desktop.background picture-options zoom
         exit;
      fi
   ;;
   ${MENU[1]}) #INTELLIGENT WALLPAPER SELECTION

      if [ ! -f $IMAGE_KEYS_FILE_PATH ]; then
         zenity --error --text "To use this option add some photos first";
         exit;
      fi

      generate_question "Do You want to get more energetic" "Dynamic" "Static"
      generate_question "Warm over cold" "WarmColours" "ColdColours"
      generate_question "Brightness over darkness" "Brightness" "Darkness"
      generate_question "Do You have nostalgic feels" "Nostalgia" "Modernity"
      generate_question "Do You need some touch of the nature" "Nature" "NotNature"

      #GENERATE_QUESTION PUTS KEY VALUES IN CATEGORIES[]
      for i in "${CATEGORIES[@]}";
      do
         grep "$i" $IMAGE_KEYS_FILE_PATH | sed "s/$i//g" >> $BUFF_FILE
      done
      cat $BUFF_FILE | sort | uniq -c | sort -rn >> $RESULT_FILE

      # READ THE FIRST LINE FROM THE FILE (IT HOLDS THE MOST OCCURED WALLPAPER AND NOW IT MUST BE CHECKED IF THERE EXIST MORE WALLPAPERS WITH THE SAME NUMBER OF OCC) 
      read -r FIRSTLINE<$RESULT_FILE
      #echo $FIRSTLINE;
      if [ ! "$FIRSTLINE" ]; then
         #delete temporary files
         rm $BUFF_FILE
         rm $RESULT_FILE
         zenity --error --text "Something went wrong. There are no suitable wallpapers. Add some of them first";
         exit;
      fi

      FIRSTLINE_NUMBER="$(echo $FIRSTLINE | cut -d ' ' -f 1)";

      grep "$FIRSTLINE_NUMBER" $RESULT_FILE >> $FINAL_FILE
      
      ITERATOR=0
      while read -r line
      do
         read_line="$line"
         NUMBER[$ITERATOR]="$(echo $read_line | cut -d ' ' -f 1)";
         VALUE[$ITERATOR]="$(echo $read_line | cut -d ' ' -f 2)";
         #echo "$read_line"
	 #echo ${NUMBER[$ITERATOR]}
	 #echo ${VALUE[$ITERATOR]}
	 ITERATOR=`expr $ITERATOR + 1`;
      done < "$FINAL_FILE"

      NUMBER_OF_MATCHED=${#NUMBER[@]};
      # if more than one
      #echo "liczba matched: $NUMBER_OF_MATCHED"

      if [[ $NUMBER_OF_MATCHED -eq 1 ]]; then
         MATCHED_WALLPAPER=${VALUE[0]};
      elif [[ $NUMBER_OF_MATCHED -eq 0 ]]; then
	 MATCHED_WALLPAPER=0;
         #delete temporary files
         rm $BUFF_FILE
         rm $RESULT_FILE
         rm $FINAL_FILE
         zenity --error --text "Something went wrong. There are no suitable wallpapers. Add some of them first";
         exit;
      else 
         RANDOM_INDEX=$(( ( RANDOM % $NUMBER_OF_MATCHED )  ));
         MATCHED_WALLPAPER=${VALUE[$RANDOM_INDEX]};
      fi
      echo "wallpaper: $MATCHED_WALLPAPER"
      #echo "$FILE_PREFIX$WALLPAPERS_DIR_PATH/$MATCHED_WALLPAPER"

      WALLPAPER_PATH="$FILE_PREFIX$WALLPAPERS_DIR_PATH/$MATCHED_WALLPAPER";
      #set the wallpaper and zoom it in order to fit the screen
      gsettings set org.gnome.desktop.background picture-uri  "$WALLPAPER_PATH"
      gsettings set org.gnome.desktop.background picture-options zoom

      #delete temporary files
      rm $BUFF_FILE
      rm $RESULT_FILE
      rm $FINAL_FILE
   ;;
   ${MENU[2]}) #ADD WALLPAPER TO THE BASE
      
      choose #hold selected file in FILE variable
      #IF USER CHOOSES A FILE ADD IT
      if [[ $FLAG_IF_CHOSEN -eq 1 ]]; then
         cp -R $FILE "$WALLPAPERS_DIR_PATH/$FILE_NAME"

         #READ ALL KEYS FROM THE KEY FILE
         ITERATOR=0
         while read -r line
         do
            KEYS[$ITERATOR]="$line";
            ITERATOR=`expr $ITERATOR + 1`;
         done < "$KEYS_PATH"

         #echo "${KEYS[@]}"
         ANS=$(for i in "${KEYS[@]}" ; do echo FALSE ; echo "$i" ; done | zenity  --list  --text "Select key values" --checklist  --column "Pick" --column "options" --separator=" ");
         SELECTED_ARRAY=($ANS);

         for i in "${SELECTED_ARRAY[@]}";
         do
            echo "$FILE_NAME $i" >> "$IMAGE_KEYS_FILE_PATH"
         done

      fi
   ;;
                         
   *)
      #zenity --warning --text "An unexpected error has occured!";
      exit;
   ;;
esac

######




