#!/bin/python3
import os
import subprocess

# Set the path of the folder you want to loop through
folder_path = './'

# Set the list of file extensions you want to search for
extensions = ['.jpg', '.jpeg', '.png', '.gif', '.mp4']

# Loop through all files in the folder
# filename must be YYYYMMDD_HHMMSS.EXTENSION
for filename in os.listdir(folder_path):
    # Get the file extension of the current file
    file_ext = os.path.splitext(filename)[1].lower()
    # Check if the file extension is in the list of extensions
    if file_ext in extensions:

        # extract the date/time information from the filename
        datetime_str = filename.split("_")[0] + " " + filename.split("_")[1]

        # set the DateTimeOriginal tag to the date/time information
        command = ["exiftool", "-DateTimeOriginal=" +
                   datetime_str, os.path.join(folder_path, filename)]
        subprocess.run(command)
        # set the DateTimeOriginal tag to the date/time information
        command = ["exiftool", "-CreateDate=" +
                   datetime_str, os.path.join(folder_path, filename)]
        subprocess.run(command)