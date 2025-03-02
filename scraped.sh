#!/bin/bash

#define base_url and url
echo "Enter base URL:"
echo "example: https://www.scrapethissite.com"
read base_url
echo "Enter URL:"
echo "example: https://www.scrapethissite.com/pages/"
read url

#create a CSV file and add a header
echo "Link,Title" > scraped_links.csv

#extract links and titles and save them to the CSV file
link_array=($(curl -s "$url" | awk -F 'href="' '/<a/{gsub(/".*/, "", $2); print $2}'))

for link in "${link_array[@]}"; do
    full_link="${base_url}${link}"
    title=$(curl -s "$full_link" | grep -o '<title[^>]*>[^<]*</title>' | sed -e 's/<title>//g' -e 's/<\/title>//g')
    echo "\"$full_link\",\"$title\"" >> scraped_links.csv
done

echo "Scraped links saved to: 'scraped_links.csv'."


#create folder
mkdir downloaded_stuff
folder_name="downloaded_stuff"
#check if scraped_links file exists
if [ ! -f "scraped_links.csv" ]; then
    echo "CSV file 'scraped_links.csv' not found!"
    exit 1
fi

#read the CSV file
tail -n +2 "scraped_links.csv" | while IFS=',' read -r link title; do
    #trim any leading or trailing spaces from the link and title
    link=$(echo "$link" | xargs)
    title=$(echo "$title" | xargs)

    #skip empty lines
    if [ -z "$link" ]; then
        continue
    fi

    #download the link
    echo "Downloading $title from $link..."

    #remove any problematic characters
    safe_title=$(echo "$title" | sed 's/[^a-zA-Z0-9_-]/_/g')
    file_name="$safe_title.html"
    #download the file
    curl -s -o "$folder_name/$file_name" "$link"

    echo "Downloaded $title from $link"
done

mv scraped_links.csv $folder_name/scraped_links.csv
echo "Links scraped and downloaded to downloaded_stuff/"
