#!/bin/bash
#
# Lazy (-_-)
# Wordpress automatic install + vhost + host + dummy-wordpress
#
# By @maximebj (maxime@smoothie-creative.com) and some stuff by INTO THE WHY
#
# *** Recommended for Lazy people like me ***
#
# How to launch Lazy ?
# bash lazy.sh sitename "My WP Blog"
# $1 = folder name & database name
# $2 = Site title

#  ===============================
# VARS 
# admin email
email="webmaster@$1.com"

# local url login
# --> Change to fit your server URL model (eg: http://localhost:8888/my-project)
url="http://"$1".com"

# admin login
admin=$1

# user bash
user=matteo

# path to install your WPs
pathtoinstall=~/Sites

# end VARS ---

#  ===============
#  = Fancy Stuff =
#  ===============
# not mandatory at all

# Stop on error
set -e

# colorize and formatting command line
# You need iTerm and activate 256 color mode in order to work : http://kevin.colyar.net/wp-content/uploads/2011/01/Preferences.jpg
green='\x1B[0;32m'
cyan='\x1B[1;36m'
blue='\x1B[0;34m'
grey='\x1B[1;30m'
red='\x1B[0;31m'
bold='\033[1m'
normal='\033[0m'

# Jump a line
function line {
  echo " "
}

# Wippy has something to say
function bot {
  line
  echo -e "${blue}${bold}=====(-_-)===== $1${normal}"
}

function ok {
  line
  echo -e "${green}${bold}++++++++++++++ $1 OK +++++++++++++++${normal}"
}

function message {
  line
  echo -e "==================${green}${bold}$1${normal}"
}


#  ==============================
#  = The show is about to begin =
#  ==============================
# Welcome !

bot "Bonjour ! Je suis Lazy"
echo -e "${cyan}${bold}                Je vais installer wordpress pour $1 en local chef !"

#  ===============================
#  CREATE VHOST & UPDATE HOST FILE
#  ===============================
bot "Création du VHOST $1"

echo "<VirtualHost *:80>
        DocumentRoot /Users/matteo/Sites/$1/
        ServerName $1.com
        ServerAlias www.$1.com
        ErrorLog "/private/var/log/apache2/$1.com-error_log"
        CustomLog "/private/var/log/apache2/$1.com-access_log" common
        <Directory /Users/matteo/Sites/$1/>
                Options +Indexes +FollowSymLinks +MultiViews +Includes
                AllowOverride All
                Order allow,deny
                allow from all
        </Directory>
</VirtualHost>" > /etc/apache2/other/$1.conf

ok "VHOST"

bot "Mise à jour du HOST $1"
echo 127.0.0.1    $1.com >> /etc/hosts
ok "HOST"

bot "Apache Restart"
apachectl restart

# CHECK :  Directory doesn't exist
# go to wordpress installs folder
# --> Change : to wherever you want
#cd pathtoinstall

# check if provided folder name already exists
if [ -d $1 ]; then
  bot "${red}Le dossier ${cyan}$1${red}existe déjà${normal}."
  echo "         Par sécurité, je ne vais pas plus loin pour ne rien écraser."
  line

  # quit script
  exit 1
fi

# create directory
bot "Je crée le dossier : ${cyan}$1"
sudo -u ${user} -- mkdir $1
cd $1

# Download WP
bot "Je télécharge WordPress..."
sudo -u ${user} -- wp core download --locale=fr_FR --force

# check version
bot "J'ai récupéré cette version :"
sudo -u ${user} -- wp core version

# create base configuration
bot "Je lance la configuration :"
sudo -u ${user} -- wp core config --dbname='wp_'$1 --dbuser=root --dbpass=admin --skip-check --extra-php <<PHP
define( 'WP_DEBUG', true );
PHP

# Create database
bot "Je crée la base de données :"
sudo -u ${user} -- wp db create

# Generate random password
passgen=`head -c 10 /dev/random | base64`
password='admin'

# launch install
bot "et j'installe !"
sudo -u ${user} -- wp core install --url=$url --title="$2" --admin_user=$admin --admin_email=$email --admin_password=$password

# Plugins install
sudo -u ${user} -- wp plugin install timber-library --activate
sudo -u ${user} -- wp plugin install ../plugins/vc.zip --activate
sudo -u ${user} -- wp plugin install jetpack --activate
sudo -u ${user} -- wp plugin install advanced-custom-fields --activate
sudo -u ${user} -- wp plugin install contact-form-7 --activate
sudo -u ${user} -- wp plugin install tinymce-advanced --activate
sudo -u ${user} -- wp plugin install wp-clean-up --activate
sudo -u ${user} -- wp plugin install wordpress-seo --activate


# Download from private git repository
bot "J'installe le theme dummy"
cd wp-content/themes/

git clone git@github.com:dummy-team/wp-dummy-twig.git

cd wp-content/themes/wp-dummy-twig/web/
yo dummies
yo dummies:toolkit

cd grunt
npm install
grunt build



# Create standard pages
bot "Je crée les pages Accueil, page et contact)"
sudo -u ${user} -- wp post create --post_type=page --post_title='Accueil' --post_status=publish
sudo -u ${user} -- wp post create --post_type=page --post_title='Page' --post_status=publish
sudo -u ${user} -- wp post create --post_type=page --post_title='Contact' --post_status=publish

# Change Homepage
bot "Je change la page d'accueil et la page des articles"
sudo -u ${user} -- wp option update show_on_front page
sudo -u ${user} -- wp option update page_on_front 3


# Menu stuff
bot "Je crée le menu principal, assigne les pages, et je lie l'emplacement du thème : "
sudo -u ${user} -- wp menu create "Menu Principal"
sudo -u ${user} -- wp menu item add-post menu-principal 3
sudo -u ${user} -- wp menu item add-post menu-principal 4
sudo -u ${user} -- wp menu item add-post menu-principal 5
#wp menu location assign menu-principal main-menu

# Misc cleanup
bot "Je supprime Hello Dolly, les thèmes de base et les articles exemples"
sudo -u ${user} -- wp post delete 1 --force # Article exemple - no trash. Comment is also deleted
sudo -u ${user} -- wp post delete 2 --force # page exemple
sudo -u ${user} -- wp plugin delete hello
sudo -u ${user} -- wp theme delete twentyfourteen
sudo -u ${user} -- wp theme delete twentyfifteen
sudo -u ${user} -- wp theme delete twentysixteen
sudo -u ${user} -- wp option update blogdescription ''

# Permalinks to /%postname%/
bot "J'active la structure des permaliens"
sudo -u ${user} -- wp rewrite structure "/%postname%/" --hard
sudo -u ${user} -- wp rewrite flush --hard

# cat and tag base update
sudo -u ${user} -- wp option update category_base theme
sudo -u ${user} -- wp option update tag_base sujet

# Git project
# REQUIRED : download Git at http://git-scm.com/downloads
bot "Je Git le projet :"
cd pathtoinstall
cd $1
git init    # git project
git add -A  # Add all untracked files
#touch README
git commit -m "Initial commit"   # Commit changes
#git remote add origin https://github.com/itwhy/$1.git
#git push

# Open the stuff
bot "Je lance le navigateur, Bracket et le finder."

# Open in browser
open $url
open "${url}/wp-admin"

# Open in Sublime text
# REQUIRED : activate subl alias at https://www.sublimetext.com/docs/3/osx_command_line.html
cd wp-content/themes
brackets .
#subl .

# Open in finder
open .

# Copy password in clipboard
echo $password | pbcopy

# That's all ! Install summary
bot "${green}L'installation est terminée !${normal}"
line
echo "URL du site:   $url"
echo "Login admin :  admin$1"
echo -e "Password :  ${cyan}${bold} $password ${normal}${normal}"
line
echo -e "${grey}(N'oubliez pas le mot de passe ! Je l'ai copié dans le presse-papier)${normal}"

line
bot "à Bientôt !"
line
line
